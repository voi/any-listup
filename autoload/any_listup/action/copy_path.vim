let s:save_cpo = &cpo
set cpo&vim

"""
let s:actions = {}


"""
function! s:set_pathes(candidates, modifier) abort "{{{
  call setreg(any_listup#common#get_default_reg(),
      \ join(map(filter(a:candidates, 'has_key(v:val, "path")'),
      \   'fnamemodify(v:val.path, a:modifier)'), "\n"))
endfunction "}}}


"""
let s:actions.copy_fullpath = { 'description': 'copy full path' }
function! s:actions.copy_fullpath.do(context, candidates) abort "{{{
  call s:set_pathes(a:candidates, ':p')
endfunction "}}}

let s:actions.copy_file_name = { 'description': 'copy file name' }
function! s:actions.copy_file_name.do(context, candidates) abort "{{{
  call s:set_pathes(a:candidates, ':t')
endfunction "}}}

let s:actions.copy_directory_name = { 'description': 'copy directory name' }
function! s:actions.copy_directory_name.do(context, candidates) abort "{{{
  call s:set_pathes(a:candidates, ':h')
endfunction "}}}


function! any_listup#action#copy_path#get_actions() abort "{{{
  return s:actions
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
" vim: foldmethod=marker
