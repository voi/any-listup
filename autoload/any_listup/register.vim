let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'put_reg',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let l:ret = ''

  redir => l:ret
  silent registers
  redir END

  let a:context.bufnr = bufnr('%')
  let a:context.registers = l:ret
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return map(split(get(a:context, 'registers', ''), "\n")[1:], '{ "caption": v:val }')
endfunction "}}}

let s:source.actions.put_reg = { 'description': 'put selected register value' }
function! s:source.actions.put_reg.do(context, candidates) abort "{{{
  let l:winnr = bufwinnr(get(a:context, 'bufnr', -1))

  if l:winnr > 0
    execute l:winnr . 'wincmd w'
  else
    wincmd w
  endif

  for l:candidate in a:candidates
    execute 'normal! ' . matchstr(get(l:candidate, 'caption', ''), '^\S\+\ze.*') . 'p'
  endfor
endfunction "}}}


"""
function! any_listup#register#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.register = s:source
endfunction "}}}


let &cpo = s:save_cpo
