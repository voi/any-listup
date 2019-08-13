let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'goto_mark',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let l:ret = ''

  redir => l:ret
  silent marks
  redir END

  let a:context.marks = l:ret
  let a:context.bufnr = bufnr('%')
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return map(split(get(a:context, 'marks', ''), "\n")[1:], '{ "caption": v:val }')
endfunction "}}}

let s:source.actions.goto_mark = { 'description': 'goto selected mark position' }
function! s:source.actions.goto_mark.do(context, candidates) abort "{{{
  let l:winnr = bufwinnr(get(a:context, 'bufnr', -1))

  if l:winnr > 0
    execute l:winnr . 'wincmd w'
  else
    wincmd w
  endif

  for l:candidate in a:candidates
    execute "normal! g'" . matchstr(get(l:candidate, 'caption', ''), '^\s*\zs\S\+\ze\s.*')
  endfor
endfunction "}}}


"""
function! any_listup#mark#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.mark = s:source
endfunction "}}}


let &cpo = s:save_cpo
