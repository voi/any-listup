let s:save_cpo = &cpo
set cpo& " vim

"""
function! s:git_quote(path) abort "{{{
  return any_listup#vcs_util#quote(escape(a:path, ' '))
endfunction "}}}

function! s:git_get_root(params) abort "{{{
  return any_listup#vcs_util#quote(
      \ any_listup#vcs_util#get_root(get(a:params, 'cd', ''), '.git'))
endfunction "}}}

function! s:git_commandline(root, command, entry) abort "{{{
  return printf('cd %s | git %s %s', a:root, a:command, s:git_quote(a:entry))
endfunction "}}}

function! s:git_get_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#systemlist(
      \ s:git_commandline(a:root, a:command, a:entry), 'utf-8')
endfunction "}}}

function! s:git_do_command(root, command, entry) abort "{{{
  return any_listup#vcs_util#system(
      \ s:git_commandline(a:root, a:command, a:entry), 'utf-8')
endfunction "}}}

function! s:git_each_command_output(command, context, candidates, ext) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    let output = s:git_get_command(l:root, a:command, l:candidate.entry)
    let output_tmp = fnamemodify(tempname() . a:ext, ':p')

    call writefile(output, output_tmp)

    execute printf('silent! tabe +set\ ro %s', output_tmp)
  endfor
endfunction "}}}

function! s:git_each_command(command, context, candidates) abort "{{{
  let l:root = a:context.root

  for l:candidate in a:candidates
    echomsg s:git_do_command(l:root, a:command, l:candidate.entry)
  endfor
endfunction "}}}

function! s:git_each_branch_command(command, context, candidates) abort
  call s:git_each_command(a:command, a:context, a:candidates)
endfunction "}}}

function! s:git_make_source_params(files, command) abort "{{{
  let l:context = { 'root': s:git_get_root({}) }

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

function! s:git_command_get_output(files, command) abort "{{{
  let [ l:context, l:candidates ] = s:git_make_source_params(a:files, a:command)

  call s:git_each_command_output(a:command, l:context, l:candidates, '.git-' . a:command)
endfunction "}}}

function! s:git_command_do(files, command) abort "{{{
  let [ l:context, l:candidates ] = s:git_make_source_params(a:files, a:command)

  call s:git_each_command(a:command, l:context, l:candidates)
endfunction "}}}


"""
let s:actions = {}

let s:actions.add = { 'description': '' }
function! s:actions.add.do(context, candidates) abort "{{{
  call s:git_each_command('add', a:context, a:candidates)
endfunction "}}}

let s:actions.remove = { 'description': '' }
function! s:actions.remove.do(context, candidates) abort "{{{
  call s:git_each_command('rm --cached', a:context, a:candidates)
endfunction "}}}

let s:actions.checkout = { 'description': '' }
function! s:actions.checkout.do(context, candidates) abort "{{{
  call s:git_each_command('checkout HEAD -- ', a:context, a:candidates)
endfunction "}}}

let s:actions.log = { 'description': '' }
function! s:actions.log.do(context, candidates) abort "{{{
  call s:git_each_command_output('log', a:context, a:candidates, '.git-log')
endfunction "}}}

let s:actions.diff = { 'description': '' }
function! s:actions.diff.do(context, candidates) abort "{{{
  call s:git_each_command_output('diff', a:context, a:candidates, '.git-diff')
endfunction "}}}

let s:actions.blame = { 'description': '' }
function! s:actions.blame.do(context, candidates) abort "{{{
  call s:git_each_command_output('blame', a:context, a:candidates, '.git-blame')
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
  let a:context.root = s:git_get_root(a:params)
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return []
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  " --------------------------
  " ' ' = unmodified
  " 'M' = modified
  " 'A' = added
  " 'D' = deleted
  " 'R' = renamed
  " 'C' = copied
  " 'U' = updated but unmerged
  " --------------------------
  "  X  Y Meaning
  " --------------------------
  "  ?  ? untracked
  "  !  ! ignored
  " --------------------------
  let l:pattern = '^\(.\{2}\)\s\+\(.\+\)'
  let l:root = fnamemodify(a:context.root, ':p')
  let l:entries = filter(map(s:git_get_command(a:context.root, 'status -s', ''),
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
  let a:context.root = s:git_get_root(a:params)
endfunction "}}}

function! s:source_ls.get_candidates(context) abort "{{{
  let l:root = fnamemodify(a:context.root, ':p')
  let l:entries = s:git_get_command(a:context.root, 'ls-files -co --exclude-standard', '')

  return map(l:entries, '{
      \ "caption": v:val, "path": fnamemodify(l:root . v:val, ":p"), "entry": v:val
      \ }')
endfunction "}}}


"""
let s:source_conflicts = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'resolve',
    \ 'type': 'list',
    \ 'no_multi_select': 0
    \ }


"""
function! s:source_conflicts.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:git_get_root(a:params)
endfunction "}}}

function! s:source_conflicts.get_candidates(context) abort "{{{
  let conflicts = s:git_get_command(a:context.root, 'diff-files --name-status', '')

  " A: addition of a file
  " C: copy of a file into a new one
  " D: deletion of a file
  " M: modification of the contents or mode of a file
  " R: renaming of a file
  " T: change in the type of the file
  " U: file is unmerged (you must complete the merge before it can be committed)
  " X: "unknown" change type (most probably a bug, please report it)
  let l:root = fnamemodify(a:context.root, ':p')
  let files = map(filter(conflicts, 'v:val[0] == "U"'),
      \ 'get(split(v:val, "\\\s\\\+"), 1, "")')

  return map(files, '{ 
      \ "caption": v:val, "path": fnamemodify(l:root . v:val, ":p"), "entry": v:val
      \ }')
endfunction "}}}

let s:source_conflicts.actions.resolve = { 'description': '' }
function! s:source_conflicts.actions.resolve.do(context, candidates) abort "{{{
  call s:git_each_command('add', a:context, a:candidates)
endfunction "}}}


"""
let s:source_branch = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'checkout',
    \ 'type': 'list',
    \ 'no_multi_select': 1
    \ }


"""
function! s:source_branch.hooks.on_ready(context, params) abort "{{{
  let a:context.root = s:git_get_root(a:params)
endfunction "}}}

function! s:source_branch.get_candidates(context) abort "{{{
  let branches = s:git_get_command(a:context.root, 'branch', '')

  return map(branches, '{ "caption": v:val, "entry": v:val }')
endfunction "}}}

let s:source_branch.actions.checkout = { 'description': '' }
function! s:source_branch.actions.checkout.do(context, candidates) abort "{{{
  call s:git_each_branch_command('checkout', a:context, a:candidates)
endfunction "}}}

let s:source_branch.actions.delete = { 'description': '' }
function! s:source_branch.actions.delete.do(context, candidates) abort "{{{
  call s:git_each_branch_command('branch -d', a:context, a:candidates)
endfunction "}}}

let s:source_branch.actions.merge = { 'description': '' }
function! s:source_branch.actions.merge.do(context, candidates) abort "{{{
  call s:git_each_branch_command('merge --no-ff', a:context, a:candidates)
endfunction "}}}


"""
function! any_listup#vcs_git#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})

  " git
  call extend(s:source.actions, s:actions)
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['git'] = s:source

  " git/ls
  for l:cmd in [ 'log', 'diff', 'blame' ]
    let s:source_ls.actions[l:cmd] = s:actions[l:cmd]
  endfor
  call extend(s:source_ls.actions, any_listup#action#file_open#get_actions())
  call extend(s:source_ls.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['git/ls'] = s:source_ls

  " git/conflicts
  call extend(s:source_conflicts.actions, any_listup#action#file_open#get_actions())
  call extend(s:source_conflicts.actions, any_listup#action#copy_path#get_actions())
  let g:any_listup__sources['git/conflicts'] = s:source_conflicts

  " git/branch
  let g:any_listup__sources['git/branch'] = s:source_branch
endfunction "}}}

function! any_listup#vcs_git#make_commands() abort "{{{
  command! -nargs=? -complete=file GitLog    call s:git_command_get_output([<f-args>], 'log')
  command! -nargs=? -complete=file GitDiff   call s:git_command_get_output([<f-args>], 'diff')
  command! -nargs=? -complete=file GitBlame  call s:git_command_get_output([<f-args>], 'blame')

  command! -nargs=? -complete=file GitAdd    call s:git_command_do([<f-args>], 'add')
  command! -nargs=? -complete=file GitRevert call s:git_command_do([<f-args>], 'checkout --')
  command! -nargs=? -complete=file GitReset  call s:git_command_do([<f-args>], 'reset --')
endfunction "}}}


let &cpo = s:save_cpo
