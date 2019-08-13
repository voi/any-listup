let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open'
    \ }


"""
function! s:source.hooks.on_init(context, params) abort "{{{
  call any_listup#action#file_open#default_keymap()
endfunction "}}}

function! s:source.hooks.on_ready(context, params) abort "{{{
  let a:context.start_bufnr = bufnr('%')
endfunction "}}}

function! s:bufnr_to_candidate(bufnr, bufname) abort "{{{
  return {
      \ 'caption': printf("%4d\t%s", a:bufnr, a:bufname),
      \ 'bufnr': a:bufnr, 'path': a:bufname
      \ }
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  let l:bufnrs = filter(range(1, bufnr('$')),
      \ 'bufexists(v:val) && buflisted(v:val) && getbufvar(v:val, "&modifiable")')

  return map(l:bufnrs, 's:bufnr_to_candidate(v:val, fnamemodify(bufname(v:val), ":p"))')
endfunction "}}}

let s:source.actions.delete = { 'description': 'wipeout buffers' }
function! s:source.actions.delete.do(context, candidates) abort "{{{
  for l:candidate in a:candidates
    if has_key(l:candidate, 'bufnr')
      execute 'bwipeout ' . l:candidate.bufnr
    endif
  endfor
endfunction "}}}


"""
function! any_listup#buffer#register() abort "{{{
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())

  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.buffer = s:source
endfunction "}}}


let &cpo = s:save_cpo
