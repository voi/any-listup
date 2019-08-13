let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'set_font',
    \ 'type': 'list',
    \ 'no_multi_select': 1
    \ }


"""
function! s:source.get_candidates(context) abort "{{{
  return [
      \   { 'caption': printf('> %s (guifont)', &guifont), '__unselectable': 1 },
      \   { 'caption': printf('> %s (guifontwide)', &guifontwide), '__unselectable': 1 },
      \ ] + 
      \ map(copy(get(g:, 'any_listup_source_font_list', [])), '{ "caption": v:val, "fontname": v:val }')
endfunction "}}}

let s:source.actions.set_font = { 'description': 'set guifont' }
function! s:source.actions.set_font.do(context, candidates) abort "{{{
  let &guifont = get(get(a:candidates, 0, {}), 'fontname', '')
endfunction "}}}

let s:source.actions.set_wide_font = { 'description': 'set guifontwide' }
function! s:source.actions.set_wide_font.do(context, candidates) abort "{{{
  let &guifontwide = get(get(a:candidates, 0, {}), 'fontname', '')
endfunction "}}}

let s:source.actions.set_both_font = { 'description': 'set guifont and guifontwide' }
function! s:source.actions.set_both_font.do(context, candidates) abort "{{{
  let l:fontname = get(get(a:candidates, 0, {}), 'fontname', '')

  let &guifont = l:fontname
  let &guifontwide = l:fontname
endfunction "}}}


"""
function! any_listup#guifont#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.guifont = s:source
endfunction "}}}


let &cpo = s:save_cpo
