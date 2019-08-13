let s:save_cpo = &cpo
set cpo&vim


let s:memo_projects = get(g:, 'unite_source_memo_categories', {})
let s:memo_use_vimgrep = get(g:, 'unite_source_memo_use_vimgrep', 0)

let s:unite_source = {
      \ 'name': 'memo',
      \ 'hooks': {},
      \ }

function! s:unite_source.hooks.on_init(args, context) "{{{
  let a:context['source__params'] = map(
        \ filter(copy(a:args), 'v:val =~# "^project="'),
        \ 'substitute(v:val, "^project=", "", "")')
  let a:context['source__root'] = fnamemodify(bufname('%'), ':p')
endfunction "}}}

function! s:unite_source.hooks.on_syntax(args, context) "{{{
  syntax match UniteMemoNewFile     /^\s*\[.\+/ contains=UniteMemoNewFileMark,UniteMemoNewFileText
  syntax match UniteMemoNewFileMark /\[.\+\]/ contained
  syntax match UniteMemoNewFileText /.. New file ../ contained

  hi def link UniteMemoNewFileMark Title
  hi def link UniteMemoNewFileText Function

  for l:name in a:context.source__params
    let l:project = s:memo_projects[l:name]

    if !has_key(l:project, 'on_syntax')
      continue
    endif

    if type(l:project.on_syntax) !=# type(function('tr'))
      continue
    endif

    call l:project.on_syntax(a:args, a:context)
  endfor
endfunction "}}}

function! s:unite_source.gather_candidates(args, context) "{{{
  if empty(a:context.source__params)
    return s:source_memo_projects_candidates(
          \ a:context.source__root )
  else
    return s:source_memo_items_candidates(
          \ a:context.source__root,
          \ a:context.source__params)
  endif
endfunction "}}}

function! s:source_memo_projects_candidates(root) "{{{
  return map(keys(s:memo_projects), '{
          \   "word": v:val,
          \   "source": "memo",
          \   "kind": "command",
          \   "action__command": printf("Unite memo:project=%s -buffer-name=__unite_memo_", v:val)
          \ }' )
endfunction "}}}

function! s:source_memo_items_candidates(root, names) "{{{
  let l:candicate = []

  for l:name in a:names
    let l:project = s:memo_projects[l:name]
    let l:candicate += extend([{
          \   "word": printf('[%s] ** New file **', l:name),
          \   "source": printf("memo [%s]", l:name),
          \   "kind": "jump_list",
          \   "action__line": 1,
          \   "action__path": fnamemodify(l:project.path, ':p') . strftime(l:project.page_name)
          \ }],
          \ map(s:source_memo_get_info(a:root, l:project), '{
          \   "word": v:val.text,
          \   "source": printf("memo [%s]", l:name),
          \   "kind": "jump_list",
          \   "action__path": v:val.path,
          \   "action__line": v:val.lnum,
          \   "source__project": l:project
          \ }'))
  endfor

  return l:candicate
endfunction "}}}

function! s:source_memo_check_project(project) "{{{
  if has_key(a:project, 'path') &&
        \ has_key(a:project, 'pattern')
    if !has_key(a:project, 'encoding') || a:project.encoding ==# ''
      let a:project.encoding = &termencoding
    endif

    return 1
  else
    return 0
  endif
endfunction "}}}

function! s:source_memo_get_info(root, project) "{{{
  if !s:source_memo_check_project(a:project)
    return []
  endif

  let l:location = fnamemodify(expand(a:project.path), ':p')
  let l:list = []

  if has('win32')
    let l:cmdline = printf('findstr /R /N /S /C:"%s" /D:"%s" "%s"',
          \ a:project.pattern, substitute(l:location, '[\\/]$', '', ''), a:project.file)
  else
    let l:cmdline = printf('grep -rnH -e "%s" --include="%s" %s ',
          \ a:project.pattern, a:project.file, substitute(l:location, '[\\/]$', '', ''))
  endif

  if has('iconv') && &encoding != &termencoding
    let l:cmdline = iconv(l:cmdline, &encoding, &termencoding)
  endif

  silent let l:output = system(l:cmdline)

  if has('iconv') && &encoding != a:project.encoding
    let l:output = iconv(l:output, a:project.encoding, &encoding)
  endif

  let l:list = split(l:output, '\n')
  let l:list = map(l:list, 'matchlist(v:val, "\\v(%([A-Z]:)?[^:]+):(\\d+):(.+)$")')
  let l:list = filter(l:list, '!empty(v:val)')

  return map(l:list, '{
        \ "path": fnamemodify(l:location . v:val[1], ":p"),
        \ "lnum": str2nr(v:val[2]),
        \ "text": v:val[3]
        \ }')
endfunction "}}}

function! unite#sources#memo#define() "{{{
  return [ s:unite_source ]
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
