let s:save_cpo = &cpo
set cpo&vim

"""
let s:actions = {}


"""
function! s:get_texts(candidates) abort "{{{
  return join(map(filter(a:candidates, 'has_key(v:val, "caption")'), 'v:val.caption'), "\n")
endfunction "}}}


"""
let s:actions.paste = { 'description': 'paste selected candidates caption' }
function! s:actions.paste.do(context, candidates) abort "{{{
  call any_listup#common#jump_prev_window(a:context)

  let l:reg_chr = any_listup#common#get_default_reg()
  let l:org_reg = getreg(l:reg_chr)

  call setreg(l:reg_chr, s:get_texts(a:candidates))

  execute 'normal! "' . l:reg_chr . 'p'

  call setreg(l:reg_chr, l:org_reg)
endfunction "}}}

let s:actions.yank = { 'description': 'yank selected candidates caption' }
function! s:actions.yank.do(context, candidates) abort "{{{
  call setreg(any_listup#common#get_default_reg(), s:get_texts(a:candidates))
endfunction "}}}

let s:actions.echo = { 'description': 'echo selected candidates caption' }
function! s:actions.echo.do(context, candidates) abort "{{{
  redraw | echomsg s:get_texts(a:candidates)
endfunction "}}}


"""
function! any_listup#action#word_ope#get_actions() abort "{{{
  return s:actions
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
" vim: foldmethod=marker
