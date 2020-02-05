let s:FALSE = 0
let s:TRUE = 1


" path to the julia binary to communicate with
if has('win32') || has('win64')
    if exists('g:lsp_julia_path')
        " use assigned g:lsp_julia_path
    elseif executable('julia')
        " use julia command in PATH
        let g:lsp_julia_path = 'julia'
    else
        " search julia binary in the default installation paths
        let l:pathlist = sort(glob($LOCALAPPDATA . '\Julia-*\bin\julia.exe', 1, 1))
        let g:lsp_julia_path = get(l:pathlist, -1, 'julia')
    endif
else
    let g:lsp_julia_path = get(g:, 'lsp_julia_path', 'julia')
endif


let s:SEPARATOR = has('win32') && !&shellslash ? '\' : '/'
function! s:joinpath(...) abort
    return join(a:000, s:SEPARATOR)
endfunction


let s:DEPOTLSPJULIA = s:joinpath(expand('<sfile>:h:h'), 'depot', 'lsp-julia')
let s:JULIA_PKGDIR = s:joinpath(s:DEPOTLSPJULIA, 'julia_pkgdir')
let s:PACKAGESPATH = s:joinpath(s:DEPOTLSPJULIA, 'packages')
let s:STARTSCRIPT = s:joinpath(s:DEPOTLSPJULIA, 'startserver.jl')


function! s:is_projectroot(dir) abort
    if filereadable(s:joinpath(a:dir, 'Project.toml'))
        return s:TRUE
    endif
    if filereadable(s:joinpath(a:dir, 'JuliaProject.toml'))
        return s:TRUE
    endif
    return s:FALSE
endfunction


" The depth to traverse path to search for 'project.toml'
let s:TRAVERSAL_DEPTH = 10

if has('win32')
    function! s:projectroot(file) abort
        let l:shellslash = &shellslash
        set noshellslash
        try
            let l:projectroot = s:_projectroot(a:file)
        finally
            let &shellslash = l:shellslash
        endtry
        return l:projectroot
    endfunction
else
    function! s:projectroot(file) abort
        return s:_projectroot(a:file)
    endfunction
endif

function! s:_projectroot(file) abort
    let l:path = fnamemodify(a:file, ':p:h')
    for _ in range(1, s:TRAVERSAL_DEPTH)
        if s:is_projectroot(l:path)
            return l:path
        endif
        let [l:prevpath, l:path] = [l:path, fnamemodify(l:path, ':h')]
        if l:prevpath ==# l:path
            break
        endif
    endfor
    return ''
endfunction


" Return the project root path of the current buffer
" NOTE: Return empty string if the current buffer does not belong to any project
function! s:envpath(filename) abort
    let l:projectroot = s:projectroot(a:filename)
    return '"' . l:projectroot . '"'
endfunction


" The place to put compiled cache and logs
let g:lsp_julia_depot_path = get(g:, 'lsp_julia_depot_path', s:JULIA_PKGDIR)


let g:lsp_julia_use_global_packages = get(g:, 'lsp_julia_use_global_packages', s:FALSE)

" Return the command and arguments to start the language server
function! lsp_julia#start_cmd(...) abort
    let l:filename = get(a:000, 0, bufname())
    let l:cmd = [&shell, &shellcmdflag]
    call add(l:cmd, g:lsp_julia_path)
    call add(l:cmd, '--startup-file=no')
    call add(l:cmd, '--history-file=no')
    if !g:lsp_julia_use_global_packages
        call add(l:cmd, '--project=' . s:PACKAGESPATH)
    endif
    call add(l:cmd, s:STARTSCRIPT)
    call add(l:cmd, g:lsp_julia_depot_path)
    call add(l:cmd, s:envpath(l:filename))
    return l:cmd
endfunction


let g:lsp_julia_message_log = []

function! lsp_julia#update() abort
    let l:cwd = getcwd()
    call chdir(s:PACKAGESPATH)
    try
        let l:result = system('git submodule update --init --recursive')
    finally
        call chdir(l:cwd)
    endtry
    call extend(g:lsp_julia_message_log, split(l:result, '\r\n'))
endfunction

" vim:set sts=4 sw=4 et:
