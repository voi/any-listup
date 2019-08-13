let s:is_windows = has('win64') + has('win32') + has('win95') + has('win16')

function! any_listup#vcs_util#get_root(path, name) abort
  "
  let l:lcd = a:path

  if l:lcd !=# ''
    let l:lcd = fnamemodify(l:lcd, ':p')
  else
    let l:bufname = bufname('%')

    if l:bufname !=# ''
      let l:lcd = fnamemodify(l:bufname, ':p:h')
    else
      let l:lcd = fnamemodify(getcwd(), ':p:h')
    endif
  endif

  "
  if s:is_windows
    let l:lcd = substitute(l:lcd, '\/', '\\', 'g')
  else
    let l:lcd = substitute(l:lcd, '\\', '/', 'g')
  endif

  let l:lcd = substitute(l:lcd, '[/\\]$', '', '')

  if l:lcd ==# ''
    return '.'
  endif

  "
  let l:repo = finddir(a:name, l:lcd . ';')

  if l:repo ==# ''
    return '.'
  endif

  return fnamemodify(fnamemodify(l:repo, ':h'), ':p')
endfunction

function! any_listup#vcs_util#system(command, out_encoding)
  if s:is_windows
    let l:command = a:command
  else
    let l:command = printf('LANG=en_US.utf8  %s', a:command)
  endif

  if has('iconv') && (a:out_encoding != &encoding)
    let l:command = iconv(l:command, &encoding, a:out_encoding)
  endif

  echomsg l:command
  let l:output = system(l:command)

  if has('iconv') && (a:out_encoding != &encoding)
    let l:output = iconv(l:output, a:out_encoding, &encoding)
  endif

  return l:output
endfunction

function! any_listup#vcs_util#systemlist(command, out_encoding) abort
  return split(any_listup#vcs_util#system(a:command, a:out_encoding), '\n')
endfunction

function! any_listup#vcs_util#quote(path) abort
  if match(a:path, ' ') < 0
    return a:path
  else
    return printf('"%s"', a:path)
  endif
endfunction

function! any_listup#vcs_util#path_relative(root, path) abort "{{{
  let l:root = fnamemodify(a:root, ':p')
  let l:path = fnamemodify(a:path, ':p')

  if l:root !=# strpart(l:path, 0, len(l:root))
    return fnamemodify(a:path, ':.')
  else
    return strpart(l:path, len(l:root))
  endif
endfunction "}}}

