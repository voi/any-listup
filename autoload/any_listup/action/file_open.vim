let s:save_cpo = &cpo
set cpo&vim

"""
let s:actions = {}


"""
function! s:buffer_open_actions(file_command, buffer_command, context, candidates) abort "{{{
  for l:candidate in filter(a:candidates, 'has_key(v:val, "path")')
    let l:path = get(l:candidate, 'path', '')
    let l:bufnr = get(l:candidate, 'bufnr', bufnr(l:path))

    if a:buffer_command !=# '' && bufexists(l:bufnr)
      execute printf(a:buffer_command, l:bufnr)
    else
      execute printf(a:file_command, l:path)
    endif

    let l:pos = getpos('.')
    call cursor(get(l:candidate, 'line_nr', l:pos[1]), l:pos[2])
  endfor
endfunction "}}}


"""
let s:actions.open = { 'description': 'open current buffer' }
function! s:actions.open.do(context, candidates) abort "{{{
  call any_listup#common#jump_prev_window(a:context)
  call s:buffer_open_actions('edit %s', 'buffer %d', a:context, a:candidates)
endfunction "}}}

let s:actions.split = { 'description': 'open horizontal split window' }
function! s:actions.split.do(context, candidates) abort "{{{
  call any_listup#common#jump_prev_window(a:context)
  call s:buffer_open_actions('split %s', 'split | buffer %d', a:context, a:candidates)
endfunction "}}}

let s:actions.vsplit = { 'description': 'open vertical split window' }
function! s:actions.vsplit.do(context, candidates) abort "{{{
  call any_listup#common#jump_prev_window(a:context)
  call s:buffer_open_actions('vsplit %s', 'vsplit | buffer %d', a:context, a:candidates)
endfunction "}}}

let s:actions.tabopen = { 'description': 'open tab window' }
function! s:actions.tabopen.do(context, candidates) abort "{{{
  call s:buffer_open_actions('tabedit %s', 'tab split | buffer %d', a:context, a:candidates)
endfunction "}}}

let s:actions.tabdrop = { 'description': 'open or jump tab window'}
function! s:actions.tabdrop.do(context, candidates) abort "{{{
  call s:buffer_open_actions('tab drop %s', '', a:context, a:candidates)
endfunction "}}}


"""
function! any_listup#action#file_open#default_keymap() abort "{{{
  if any_listup#is_default_keymap_disabled()
    return
  endif

  nmap <silent> <buffer> t :call any_listup#do_specified_action('tabopen')<CR>
  nmap <silent> <buffer> d :call any_listup#do_specified_action('tabdrop')<CR>
  nmap <silent> <buffer> s :call any_listup#do_specified_action('split')<CR>
  nmap <silent> <buffer> v :call any_listup#do_specified_action('vsplit')<CR>
endfunction "}}}

function! any_listup#action#file_open#get_actions() abort "{{{
  return s:actions
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
" vim: foldmethod=marker
