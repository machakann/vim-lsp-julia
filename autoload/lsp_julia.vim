" NOTE: The word "project" points the julia project editing with the language server
" NOTE: "depot_path" is the path to the source files, compiled cache, and logs
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


let s:SEPARATOR = has('win32') ? '\' : '/'
function! s:joinpath(...) abort
    return join(a:000, s:SEPARATOR)
endfunction


function! s:doublequote(str) abort
    return printf('"%s"', a:str)
endfunction


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
    return fnamemodify(a:file, ':p:h')
endfunction

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


if has('win32') && &shellslash
    set noshellslash
    try
        let s:__BASE__ = s:joinpath(expand('<sfile>:h:h'), 'depot', 'lsp-julia')
    finally
        set shellslash
    endtry
else
    let s:__BASE__ = s:joinpath(expand('<sfile>:h:h'), 'depot', 'lsp-julia')
endif


" The place to put package files, cache, logs, etc.
let g:lsp_julia_base_path = get(g:, 'lsp_julia_base_path', s:__BASE__)


function! s:depot_path(base_path) abort
    return s:joinpath(a:base_path, 'depot')
endfunction


function! s:start_script(base_path) abort
    return s:joinpath(a:base_path, 'startserver.jl')
endfunction


" Return the command and arguments to start the language server
function! lsp_julia#start_cmd(...) abort
    let l:start_script = s:start_script(g:lsp_julia_base_path)
    let l:filename = get(a:000, 0, bufname())
    let l:env_path = s:projectroot(l:filename)
    let l:cmd = []
    call add(l:cmd, g:lsp_julia_path)
    call add(l:cmd, '--startup-file=no')
    call add(l:cmd, '--history-file=no')
    call add(l:cmd, l:start_script)
    call add(l:cmd, s:doublequote(l:env_path))
    call add(l:cmd, s:doublequote(g:lsp_julia_base_path))
    return l:cmd
endfunction


function! s:setenv_prefix(base_path) abort
    let l:depot = s:depot_path(a:base_path)
    if has('win32')
        let l:env = printf('(set JULIA_DEPOT_PATH=%s;)&&', l:depot)
    else
        let l:env = printf('JULIA_DEPOT_PATH="%s:"', l:depot)
    endif
    return l:env
endfunction


function! s:install(julia_path, base_path) abort
    let l:env = s:setenv_prefix(a:base_path)
    let l:options = join([
   \  '--startup-file=no',
   \  '--history-file=no',
   \  '--quiet',
   \  '--project=@lsp',
   \  '--eval "import Pkg;Pkg.add(\"LanguageServer\")"',
   \])
    let l:command = join([l:env, a:julia_path, l:options])
    return system(l:command)
endfunction


function! s:update(julia_path, base_path) abort
    let l:env = s:setenv_prefix(a:base_path)
    let l:options = join([
   \  '--startup-file=no',
   \  '--history-file=no',
   \  '--quiet',
   \  '--project=@lsp',
   \  '--eval "import Pkg;Pkg.update()"',
   \])
    let l:command = join([l:env, a:julia_path, l:options])
    return system(l:command)
endfunction


let g:lsp_julia_message_log = []

function! lsp_julia#update() abort
    let l:depot = s:depot_path(g:lsp_julia_base_path)
    let l:lsp_toml = s:joinpath(l:depot, 'environments', 'lsp', 'Project.toml')
    if !filereadable(l:lsp_toml)
        let l:result = s:install(g:lsp_julia_path, g:lsp_julia_base_path)
    else
        let l:result = s:update(g:lsp_julia_path, g:lsp_julia_base_path)
    endif
    call extend(g:lsp_julia_message_log, split(l:result, '\n'))
endfunction

" vim:set sts=4 sw=4 et:
