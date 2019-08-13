let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }

let s:mru_list = []


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let a:context.start_bufnr = bufnr('%')
endfunction "}}}

function! s:source.hooks.on_init(context, params) abort "{{{
  call any_listup#action#file_open#default_keymap()
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return map(copy(s:mru_list), '{ "caption": v:val, "path": v:val }')
endfunction "}}}


"""
function! s:mru_ignore_pattern() abort "{{{
  return get(g:, 'any_listup_source_mru_ignore_pattern', '[/\\][Tt]e\?mp[/\\]')
endfunction "}}}

function! s:mru_ignore_filetypes() abort "{{{
  return get(g:, 'any_listup_source_mru_ignore_filetypes', ['help'])
endfunction "}}}

function! s:mru_record_file(path) abort "{{{
  let l:path = fnamemodify(expand(a:path), ':p')
  let l:bufnr = bufnr(l:path)

  if !bufexists(l:bufnr) || !buflisted(l:bufnr) || !getbufvar(l:bufnr, "&modifiable")
    return
  endif

  if index(s:mru_ignore_filetypes(), getbufvar(l:bufnr, "&filetype")) >= 0
    return
  endif

  if !empty(s:mru_list)
    let l:ignore_pattern = s:mru_ignore_pattern()

    if has('win32') || has('win64')
      if l:path =~? l:ignore_pattern
        return
      endif

      call filter(s:mru_list, 'v:val !=? l:path')
    else
      if l:path =~# l:ignore_pattern
        return
      endif

      call filter(s:mru_list, 'v:val !=# l:path')
    endif

  endif

  call insert(s:mru_list, l:path)

  let l:max_count = get(g:, 'any_listup_source_mru_history_max', 50)

  if len(s:mru_list) > l:max_count
    let s:mru_list = s:mru_list[ : l:max_count - 1 ]
  endif
endfunction "}}}

function! s:mru_get_cache_path() abort "{{{
  return fnamemodify(get(g:, 'any_listup_source_mru_cache_path', '~/.any_listup_mru'), ':p')
endfunction "}}}

function! s:mru_restore() abort "{{{
  let l:path = s:mru_get_cache_path()

  if filereadable(l:path)
    let s:mru_list = readfile(l:path)

    call filter(s:mru_list, 'filereadable(v:val)')
  endif
endfunction "}}}

function! s:mru_save() abort "{{{
  let l:path = s:mru_get_cache_path()

  call filter(s:mru_list, 'filereadable(v:val)')
  call writefile(s:mru_list, l:path)
endfunction "}}}


"""
function! any_listup#mru#register() abort "{{{
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())

  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.mru = s:source

  augroup any_listup_mru_autocmd_group
    autocmd!
    autocmd BufReadPost,BufNewFile,BufWritePost * call s:mru_record_file('<afile>')
    autocmd VimEnter * call s:mru_restore()
    autocmd VimLeavePre * call s:mru_save()
  augroup END
endfunction "}}}


let &cpo = s:save_cpo
