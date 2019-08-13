let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': '',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  
endfunction "}}}

function! s:source.hooks.on_init(context, params) abort "{{{
  
endfunction "}}}

function! s:source.hooks.on_close(context) abort "{{{
  
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return []
endfunction "}}}

let s:source.actions.user_action = { 'description': '' }
function! s:source.actions.user_action.do(context, candidates) abort "{{{
  
endfunction "}}}


"""
function! any_listup#source_template#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.source_template = s:source
endfunction "}}}


let &cpo = s:save_cpo
