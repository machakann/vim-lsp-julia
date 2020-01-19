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

function! s:projectroot(file) abort
    let l:shellslash = &shellslash
    try
        let l:path = fnamemodify(a:file, ':p:h')
        for _ in range(1, s:TRAVERSAL_DEPTH)
            if s:is_projectroot(l:path)
                return l:path
            endif

            let l:prevpath = l:path
            let l:path = fnamemodify(l:path, ':h')
            if l:prevpath ==# l:path
                break
            endif
        endfor
    finally
        let &shellslash = l:shellslash
    endtry
    return ''
endfunction


" Return the project root path of the current buffer
" NOTE: Return empty string if the current buffer does not belong to any project
function! s:envpath() abort
    let l:filename = bufname()
    let l:projectroot = s:projectroot(l:filename)
    return '"' . l:projectroot . '"'
endfunction


" Return $JULIA_DEPOT_PATH
" NOTE: Return empty string if $JULIA_DEPOT_PATH does not exist
function! s:depotpath() abort
    let l:depotpath = exists('$JULIA_DEPOT_PATH') ? $JULIA_DEPOT_PATH : ''
    return '"' . l:depotpath . '"'
endfunction


" Return the command and arguments to start the language server
function! lsp_julia#start_cmd() abort
    let l:cmd = []
    call add(l:cmd, g:lsp_julia_path)
    call add(l:cmd, '--startup-file=no')
    call add(l:cmd, '--history-file=no')
    call add(l:cmd, '--project=' . s:PACKAGESPATH)
    call add(l:cmd, s:STARTSCRIPT)
    call add(l:cmd, s:envpath())
    call add(l:cmd, s:depotpath())
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