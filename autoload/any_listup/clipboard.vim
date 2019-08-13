" 
let s:save_cpo = &cpo
set cpo&vim


"
let s:clipboard_histories = []
"
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'yank'
    \ }


function! s:source.hooks.on_ready(context, params) abort "{{{
  let a:context.start_bufnr = bufnr('%')
endfunction "}}}

function! s:source.get_candidates(context) "{{{
  return map(copy(s:clipboard_histories), '{ "caption" : v:val }')
endfunction "}}}


"""
function! s:check_clipboard() abort "{{{
  let l:word = getreg(any_listup#common#get_default_reg())

  if l:word ==# ''
    return
  endif

  if !empty(s:clipboard_histories)
    if s:clipboard_histories[0] ==# l:word
      return
    endif

    call filter(s:clipboard_histories, 'v:val !=# l:word')
  endif

  call insert(s:clipboard_histories, l:word)

  let l:history_limit = get(g:, 'any_listup_source_clipboard_history_max', 30)

  if l:history_limit < len(s:clipboard_histories)
    let s:clipboard_histories =s:clipboard_histories[ : l:history_limit - 1]
  endif
endfunction "}}}


"""
function! any_listup#clipboard#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.clipboard = s:source

  augroup any_listup_clipboard_autocmd_group
    autocmd!
    autocmd CursorMoved * call s:check_clipboard()
  augroup END
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
