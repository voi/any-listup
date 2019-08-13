" 
let s:save_cpo = &cpo
set cpo&vim


function any_listup#common#get_default_reg() abort "{{{
  if !has('clipboard')
    return '"'
  endif

  if &clipboard =~# 'unnamedplus'
    return '+'
  elseif &clipboard =~# 'unnamed'
    return '*'
  else
    return '"'
  endif
endfunction "}}}

function! any_listup#common#jump_prev_window(context) abort "{{{
  execute 'wincmd p'
  " let l:winnr = bufwinnr(get(a:context, 'from_bufnr', -1))

  " if l:winnr > 0
    " execute l:winnr . 'wincmd w'
  " else
    " execute 'wincmd p'
  " endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
