let s:save_cpo = &cpo
set cpo& " vim

"""
function! s:svn_get_root(params) abort "{{{
  return any_listup#vcs_util#quote(
      \ any_listup#vcs_util#get_root(get(a:params, 'cd', ''), '.svn'))
endfunction "}}}

function! s:svn_do_commandline(root, command, entry) abort "{{{
  return printf('cd %s | svn %s %s', a:root, a:command,
      \ any_listup#vcs_util#quote(a:entry))
endfunction "}}}

function! s:svn_get_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#systemlist(
      \ s:svn_do_commandline(a:root, a:command, a:entry), &termencoding)
endfunction "}}}

function! s:svn_do_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#system(
      \ s:svn_do_commandline(a:root, a:command, a:entry), &termencoding)
endfunction "}}}

function! s:svn_each_command_output(command, context, candidates, ext) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    let output = s:svn_get_command(l:root, a:command, l:candidate.entry)
    let output_tmp = fnamemodify(tempname() . a:ext, ':p')

    call writefile(output, output_tmp)

    execute printf('silent! tabe +set\ ro %s', output_tmp)
  endfor
endfunction "}}}

function! s:svn_each_command(command, context, candidates) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    echomsg s:svn_do_command(l:root, a:command, l:candidate.entry)
  endfor
endfunction "}}}

function! s:svn_status2candidates(context, status) abort "{{{
  let l:pattern = printf('^\(%s\)\s\+\(.\+\)', a:status)
  let l:root = fnamemodify(a:context.root, ':p')
  let l:entries = filter(map(s:svn_get_command(a:context.root, 'status', ''),
      \ 'matchlist(v:val, l:pattern)'), '!empty(v:val)')

  return map(l:entries, '{
      \ "caption": v:val[0], "path": fnamemodify(l:root . v:val[2], ":p"), "entry": v:val[2]
      \ }')
endfunction "}}}

function! s:svn_make_source_params(files, command) abort "{{{
  let l:context = { 'root': s:svn_get_root({}) }

  if empty(a:files)
    let l:candidates = [ {
        \ 'entry': any_listup#vcs_util#path_relative(l:context.root, bufname('%'))
        \ } ]
  else
    let l:candidates = map(a:files, '{
        \ "entry": any_listup#vcs_util#path_relative(l:context.root, v:val)
        \ }')
  endif

  return [ l:context, l:candidates ]
endfunction "}}}

function! s:svn_command_get_output(files, command) abort "{{{
  let [ l:context, l:candidates ] = s:svn_make_source_params(a:files, a:command)

  call s:svn_each_command_output(a:command, l:context, l:candidates, '.svn-' . a:command)
endfunction "}}}

function! s:svn_command_do(files, command) abort "{{{
  let [ l:context, l:candidates ] = s:svn_make_source_params(a:files, a:command)

  call s:svn_each_command(a:command, l:context, l:candidates)
endfunction "}}}


"""
let s:actions = {}


"""
let s:actions.add = { 'description': '' }
function! s:actions.add.do(context, candidates) abort "{{{
  call s:svn_each_command('add', a:context, a:candidates)
endfunction "}}}

let s:actions.delete = { 'description': '' }
function! s:actions.delete.do(context, candidates) abort "{{{
  call s:svn_each_command('delete --keep-local', a:context, a:candidates)
endfunction "}}}

let s:actions.revert = { 'description': '' }
function! s:actions.revert.do(context, candidates) abort "{{{
  call s:svn_each_command('revert', a:context, a:candidates)
endfunction "}}}

let s:actions.commit = { 'description': '' }
function! s:actions.commit.do(context, candidates) abort "{{{
  
endfunction "}}}

let s:actions.resolved = { 'description': '' }
function! s:actions.resolved.do(context, candidates) abort "{{{
  call s:svn_each_command('resolved', a:context, a:candidates)
endfunction "}}}

let s:actions.log = { 'description': '' }
function! s:actions.log.do(context, candidates) abort "{{{
  call s:svn_each_command_output('log', a:context, a:candidates, '.svn-log')
endfunction "}}}

let s:actions.diff = { 'description': '' }
function! s:actions.diff.do(context, candidates) abort "{{{
  call s:svn_each_command_output('diff', a:context, a:candidates, '.svn-diff')
endfunction "}}}

let s:actions.blame = { 'description': '' }
function! s:actions.blame.do(context, candidates) abort "{{{
  call s:svn_each_command_output('blame -g -r HEAD', a:context, a:candidates, '.svn-blame')
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
  let a:context.root = s:svn_get_root(a:params)
  let a:context.status = get(a:params, 'status', ' ADMRCXI?!~')
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return filter(['@status'], 'v:val =~ a:argLead')
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return s:svn_status2candidates(a:context, printf('^[%s][ MC][ L][ +][ S][ KOTB][ C]', a:context.status))
endfunction "}}}


"""
let s:source_mod = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:svn_get_root(a:params)
  let a:context.status = ' ADMRCXI!~'
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return filter(['@status'], 'v:val =~ a:argLead')
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  return s:svn_status2candidates(a:context, printf('^[%s][ MC][ L][ +][ S][ KOTB][ C]', a:context.status))
endfunction "}}}


"""
let s:source_conflict = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'open',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source_conflict.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:svn_get_root(a:params)
endfunction "}}}

function! s:source_conflict.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source_conflict.get_candidates(context) abort "{{{
  return s:svn_status2candidates(a:context, '^[ C][ C]....[ C]')
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
  let a:context.root = s:svn_get_root(a:params)
endfunction "}}}

function! s:source_ls.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source_ls.get_candidates(context) abort "{{{
  let l:root = fnamemodify(a:context.root, ':p')

  return map(s:svn_get_command(a:context.root, 'ls -R', ''), '{
      \ "caption": v:val, "path": fnamemodify(l:root . v:val, ":p"), "entry": v:val
      \ }')
endfunction "}}}


"""
function! any_listup#vcs_svn#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})

  " svn
  call extend(s:source.actions, s:actions)
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['svn'] = s:source

  " svn/mod
  call extend(s:source_mod.actions, s:source.actions)
  let g:any_listup__sources['svn/mod'] = s:source_mod

  " svn/conflict
  call extend(s:source_conflict.actions, s:actions)
  call extend(s:source_conflict.actions, any_listup#action#file_open#get_actions())
  call extend(s:source_conflict.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['svn/conflict'] = s:source_conflict

  " svn/ls
  for l:cmd in [ 'log', 'diff', 'blame' ]
    let s:source_ls.actions[l:cmd] = s:actions[l:cmd]
  endfor

  call extend(s:source_ls.actions, any_listup#action#file_open#get_actions())
  call extend(s:source_ls.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['svn/ls'] = s:source_ls
endfunction "}}}

function! any_listup#vcs_svn#make_commands() abort "{{{
  command! -nargs=? -complete=file SvnLog    call s:svn_command_get_output([<f-args>], 'log')
  command! -nargs=? -complete=file SvnDiff   call s:svn_command_get_output([<f-args>], 'diff')
  command! -nargs=? -complete=file SvnBlame  call s:svn_command_get_output([<f-args>], 'blame')

  command! -nargs=? -complete=file SvnAdd       call s:svn_command_do([<f-args>], 'add')
  command! -nargs=? -complete=file SvnRevert    call s:svn_command_do([<f-args>], 'revert')
  command! -nargs=? -complete=file SvnResolved  call s:svn_command_do([<f-args>], 'resolved')
endfunction "}}}


let &cpo = s:save_cpo
