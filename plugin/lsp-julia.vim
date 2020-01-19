" vim-lsp-julia: LanguageServer.jl support for vim-lsp
" Maintainer : Masaaki Nakamura <mckn@outlook.com>
" License    : Creative Commons 0 (CC0)

if exists("g:loaded_lsp_julia")
  finish
endif
let g:loaded_lsp_julia = 1

let s:cpo_save = &cpoptions
set cpoptions&vim


if executable('julia')
  autocmd User lsp_setup call lsp#register_server({
   \ 'name': 'julia',
   \ 'cmd': {server_info->lsp_julia#start_cmd()},
   \ 'whitelist': ['julia'],
   \ })
endif


let &cpoptions = s:cpo_save
unlet s:cpo_save
" vim: sw=2 ts=2 sts=2 et
