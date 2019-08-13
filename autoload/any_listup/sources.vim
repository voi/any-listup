let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'execute',
    \ 'type': 'list',
    \ 'no_multi_select': 1
    \ }


"""
function! s:source.get_candidates(context) abort "{{{
  return map(sort(keys(get(g:, 'any_listup__sources', {}))), '{ "caption": v:val }')
endfunction "}}}

let s:source.actions.execute = { 'description': '' }
function! s:source.actions.execute.do(context, candidates) abort "{{{
  execute 'AnyListup ' . get(get(a:candidates, 0, {}), 'caption', '')
endfunction "}}}


"""
function! any_listup#sources#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.sources = s:source
endfunction "}}}


let &cpo = s:save_cpo
