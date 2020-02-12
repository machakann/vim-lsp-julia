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
    augroup lsp-julia-lsp_setup
        autocmd!
        autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'julia',
        \ 'cmd': {server_info->lsp_julia#start_cmd()},
        \ 'whitelist': ['julia'],
        \ })
    augroup END
endif


let &cpoptions = s:cpo_save
unlet s:cpo_save
" vim: sw=4 sts=4 et
