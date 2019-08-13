let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'colorscheme',
    \ 'type': 'list',
    \ 'no_multi_select': 1
    \ }


"""
function! s:colorscheme_path()
  return get(g:, 'any_listup_source_colorscheme_path', &runtimepath)
endfunction


"""
function! s:source.get_candidates(context) abort "{{{
  return [ { 'caption': printf('> %s (colorscheme)', get(g:, 'colors_name', '')), '__unselectable': 1 } ]
      \ + map(split(globpath(s:colorscheme_path(), 'colors/*.vim'), '\n'),
      \       '{ "caption": fnamemodify(v:val, ":t:r"), "name": fnamemodify(v:val, ":t:r"), "path": v:val }')
endfunction "}}}

let s:source.actions.colorscheme = { 'description': 'change colorscheme' }
function! s:source.actions.colorscheme.do(context, candidates) abort "{{{
  execute 'colorscheme ' . get(get(a:candidates, 0, {}), 'name', '')
endfunction "}}}


"""
function! any_listup#colorscheme#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.colorscheme = s:source
endfunction "}}}


let &cpo = s:save_cpo
