" vim-lsp-julia: Sets up vim-lsp for julia
" Maintainer : Masaaki Nakamura <mckn@outlook.com>
" License    : Creative Commons 0 (CC0)

if exists("g:loaded_lsp_julia")
  finish
endif
let g:loaded_lsp_julia = 1
let s:cpo_save = &cpoptions
set cpoptions&vim

let g:lsp_julia_path = get(g:, 'lsp_julia_path', 'julia')
let s:SEPARATOR = has('win32') && !&shellslash ? '\' : '/'
let s:STARTSCRIPT = join([expand('<sfile>:h:h'), 'scripts', 'startserver.jl'], s:SEPARATOR)

if executable('julia')
  autocmd User lsp_setup call lsp#register_server({
    \ 'name': 'julia',
    \ 'cmd': {server_info->[g:lsp_julia_path, '--startup-file=no', '--history-file=no', s:STARTSCRIPT]},
    \ 'whitelist': ['julia'],
    \ })
else
  echohl ErrorMsg
  echomsg 'vim-lsp-julia: `julia` is not executable, install `julia` command first.'
  echomsg 'vim-lsp-julia: then include the executable in $PATH or set `g:lsp_julia_path`.'
  echohl NONE
endif

let &cpoptions = s:cpo_save
unlet s:cpo_save
" vim: sw=2 ts=2 sts=2 et
