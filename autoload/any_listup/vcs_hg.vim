let s:save_cpo = &cpo
set cpo& " vim

"""
function! s:hg_get_root(params) abort "{{{
  return any_listup#vcs_util#quote(
      \ any_listup#vcs_util#get_root(get(a:params, 'cd', ''), '.hg'))
endfunction "}}}

function! s:hg_do_commandline(root, command, entry) abort "{{{
  return printf('hg --cwd %s %s %s', a:root, a:command,
      \ any_listup#vcs_util#quote(a:entry))
endfunction "}}}

function! s:hg_get_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#systemlist(
      \ s:hg_do_commandline(a:root, a:command, a:entry), &termencoding)
endfunction "}}}

function! s:hg_do_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#system(
      \ s:hg_do_commandline(a:root, a:command, a:entry), &termencoding)
endfunction "}}}

function! s:hg_do_each_command_output(command, context, candidates, ext) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    let output = s:hg_get_command(l:root, a:command, l:candidate.entry)
    let output_tmp = fnamemodify(tempname() . a:ext, ':p')

    call writefile(output, output_tmp)

    execute printf('silent! tabe +set\ ro %s', output_tmp)
  endfor
endfunction "}}}

function! s:hg_do_each_command(command, context, candidates) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    echomsg s:hg_do_command(l:root, a:command, l:candidate.entry)
  endfor
endfunction "}}}

function! s:hg_command_get_output(files, command) abort "{{{
  let l:context = { 'root': s:hg_get_root({}) }

  if empty(a:files)
    let l:candidates = [ {
        \ 'entry': any_listup#vcs_util#path_relative(l:context.root, bufname('%'))
        \ } ]
  else
    let l:candidates = map(a:files, '{
        \ "entry": any_listup#vcs_util#path_relative(l:context.root, v:val)
        \ }')
  endif

  call s:hg_do_each_command_output(a:command, l:context, l:candidates, '.hg-' . a:command)
endfunction "}}}


"""
let s:actions = {}

let s:actions.add = { 'description': '' }
function! s:actions.add.do(context, candidates) abort "{{{
  call s:hg_do_each_command('add', a:context, a:candidates)
endfunction "}}}

let s:actions.addremove = { 'description': '' }
function! s:actions.addremove.do(context, candidates) abort "{{{
  call s:hg_do_each_command('addremove', a:context, a:candidates)
endfunction "}}}

let s:actions.forget = { 'description': '' }
function! s:actions.forget.do(context, candidates) abort "{{{
  call s:hg_do_each_command('forget', a:context, a:candidates)
endfunction "}}}

let s:actions.revert = { 'description': '' }
function! s:actions.revert.do(context, candidates) abort "{{{
  call s:hg_do_each_command('revert', a:context, a:candidates)
endfunction "}}}

let s:actions.commit = { 'description': '' }
function! s:actions.commit.do(context, candidates) abort "{{{
  
endfunction "}}}

let s:actions.log = { 'description': '' }
function! s:actions.log.do(context, candidates) abort "{{{
  call s:hg_do_each_command_output('log', a:context, a:candidates, '.hg-log')
endfunction "}}}

let s:actions.diff = { 'description': '' }
function! s:actions.diff.do(context, candidates) abort "{{{
  call s:hg_do_each_command_output('diff', a:context, a:candidates, '.hg-diff')
endfunction "}}}

let s:actions.annotate = { 'description': '' }
function! s:actions.annotate.do(context, candidates) abort "{{{
  call s:hg_do_each_command_output('annotate', a:context, a:candidates, '.hg-annotate')
endfunction "}}}


"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:hg_get_root(a:params)
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{

  let l:pattern = '^\(.\)\s\+\(.\+\)'
  let l:root = fnamemodify(a:context.root, ':p')
  let l:entries = filter(map(s:hg_get_command(a:context.root, 'status', ''),
      \ 'matchlist(v:val, l:pattern)'), '!empty(v:val)')

  return map(l:entries, '{
      \ "caption": v:val[0], "path": fnamemodify(l:root . v:val[2], ":p"), "entry": v:val[2]
      \ }')
endfunction "}}}


"""
let s:source_ls = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source_ls.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:hg_get_root(a:params)
endfunction "}}}

function! s:source_ls.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source_ls.get_candidates(context) abort "{{{
  let l:root = fnamemodify(a:context.root, ':p')

  return map(s:hg_get_command(a:context.root, 'locate -I .', ''), '{
      \ "caption": v:val, "path": fnamemodify(l:root . v:val, ":p"), "entry": v:val
      \ }')
endfunction "}}}


"""
function! any_listup#vcs_hg#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})

  " hg
  call extend(s:source.actions, s:actions)
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['hg'] = s:source

  " hg/ls
  for l:cmd in [ 'log', 'diff', 'annotate' ]
    let s:source_ls.actions[l:cmd] = s:actions[l:cmd]
  endfor
  call extend(s:source_ls.actions, any_listup#action#file_open#get_actions())
  call extend(s:source_ls.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['hg/ls'] = s:source_ls
endfunction "}}}

function! any_listup#vcs_hg#make_commands() abort "{{{
  command! -nargs=? -complete=file HgLog      call s:hg_command_get_output([<f-args>], 'log')
  command! -nargs=? -complete=file HgDiff     call s:hg_command_get_output([<f-args>], 'diff')
  command! -nargs=? -complete=file HgAnnotate call s:hg_command_get_output([<f-args>], 'annotate')
endfunction "}}}


let &cpo = s:save_cpo
