let s:save_cpo = &cpo
set cpo&vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'tree',
    \ 'no_multi_select': 0
    \ }
" handlers mapping to filetype "{{{
let s:handlers_map = {
    \ 'c': {
    \   'on_syntax': function('any_listup#outline#ctags#on_syntax_c_familly')
    \ },
    \ 'cpp': 'c',
    \ 'cs': 'c',
    \ 'java': 'c',
    \ 'changelog': {
    \   'get_tags': function('any_listup#outline#changelog#get_tags'),
    \   'on_syntax': function('any_listup#outline#changelog#on_syntax')
    \ },
    \ 'chalow': 'changelog',
    \ 'markdown': {
    \   'get_tags': function('any_listup#outline#markdown#get_tags')
    \ } }
"}}}


"""
function! s:outline_get_handler(filetype, name) abort "{{{
  " make handlers map
  let l:handlers_map = deepcopy(s:handlers_map)

  call extend(l:handlers_map, get(g:, 'any_listup_source_outline_handlers', {}))

  " if value is string, as filetype
  let l:handlers = get(l:handlers_map, a:filetype, {})

  if type(l:handlers) ==# type('')
    let l:handlers = get(l:handlers_map, l:handlers, {})
  endif

  " if value is function, as parse handler
  let l:Handler = get(l:handlers, a:name, 0)

  if type(l:Handler) ==# type(function('tr'))
    return l:Handler
  endif

  return 0
endfunction "}}}

function! s:outline_get_candidates(path, start_bufnr, filetype) abort "{{{
  if bufexists(a:path)
    let l:lines = getbufline(a:path, 1, '$')
  elseif bufexists(a:start_bufnr)
    let l:lines = getbufline(a:start_bufnr, 1, '$')
  else
    return []
  endif

  let l:Handler = s:outline_get_handler(a:filetype, 'get_tags')

  if type(l:Handler) ==# type(function('tr'))
    return l:Handler(a:path, a:start_bufnr, a:filetype, l:lines)
  endif

  return any_listup#outline#ctags#get_tags(a:path, a:start_bufnr, a:filetype, l:lines)
endfunction "}}}

function! s:outline_on_init(filetype) abort "{{{
  let l:Handler = s:outline_get_handler(a:filetype, 'on_syntax')

  if type(l:Handler) ==# type(function('tr'))
    return l:Handler()
  endif
endfunction "}}}

function! s:outline_on_close(filetype) abort "{{{
  let l:Handler = s:outline_get_handler(a:filetype, 'on_close')

  if type(l:Handler) ==# type(function('tr'))
    return l:Handler()
  endif
endfunction "}}}


"""
function! s:source.hooks.on_ready(context, params) "{{{
  let a:context.path = fnamemodify(expand('%'), ':p')
  let a:context.start_bufnr = bufnr('%')
  let a:context.filetype = &filetype
endfunction "}}}

function! s:source.hooks.on_init(context, params) "{{{
  " set common syntax
  syntax match AnyListOutlineSignature /(.*)\?$/

  hi def link AnyListOutlineSignature Comment

  " default keymap
  call any_listup#action#file_open#default_keymap()
  " set user syntax
  call s:outline_on_init(a:context.filetype)
endfunction "}}}

function! s:source.hooks.on_close(context) abort "{{{
  " clear common syntax
  syntax clear AnyListOutlineSignature

  hi clear AnyListOutlineSignature

  call s:outline_on_close(a:context.filetype)
endfunction "}}}

function! s:source.get_candidates(context) "{{{
  let l:path = get(a:context, 'path', '')
  let l:start_bufnr = get(a:context, 'start_bufnr', -1)
  let l:filetype = get(a:context, 'filetype', '')

  if l:path ==# '' || l:filetype ==# ''
    return []
  endif

  return s:outline_get_candidates(l:path, l:start_bufnr, l:filetype)
endfunction "}}}


"""
function! any_listup#outline#register() abort "{{{
  let s:source.actions = any_listup#action#file_open#get_actions()

  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.outline = s:source
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
" vim: foldmethod=marker
