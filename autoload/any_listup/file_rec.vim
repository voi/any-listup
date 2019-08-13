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


"""
function! s:source.hooks.on_ready(context, params) abort "{{{
  let l:path = get(a:params, 'cd', '')

  if l:path !=# ''
    let l:lcd = fnamemodify(l:path, ':p')
  else
    let l:bufname = bufname('%')

    if l:bufname !=# ''
      let l:lcd = fnamemodify(l:bufname, ':p:h')
    else
      let l:lcd = fnamemodify(getcwd(), ':p:h')
    endif
  endif

  if has('win32') || has('win64')
    let l:lcd = substitute(l:lcd, '\/', '\\', 'g')
  else
    let l:lcd = substitute(l:lcd, '\\', '/', 'g')
  endif

  let l:lcd = substitute(l:lcd, '[/\\]$', '', '')

  if !isdirectory(l:lcd)
    let l:lcd = ''
  endif

  let a:context.lcd = l:lcd
  let a:context.no_find_marker = has_key(a:params, 'force_lcd')
  let a:context.dont_ignore = has_key(a:params, 'dont_ignore')
endfunction "}}}

function! s:source.hooks.on_complete(argLead) abort "{{{
  return filter([ '@cd=', '@dont-ignore', '@force-lcd' ], 'v:val =~ a:argLead')
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  let l:path = get(a:context, 'lcd', '')

  if !isdirectory(l:path)
    return []
  endif

  let l:files = ''
  let l:user_commands = get(g:, 'any_listup_source_file_rec_commands', [])

  for l:user_command in l:user_commands
    let l:marker = get(l:user_command, 0, '')
    let l:command = get(l:user_command, 1, '')
    let l:encoding = get(l:user_command, 2, &termencoding)

    if l:command ==# ''
      continue
    endif

    if l:marker ==# ''
      silent let l:output = system(printf(l:command, l:path))

    elseif !a:context.no_find_marker
      let l:root = finddir(l:marker, l:path . ';')

      if l:root !=# ''
        silent let l:output = system(printf(l:command, fnamemodify(l:root, ':p:h')))

      else
        let l:root = findfile(l:marker, l:path . ';')

        if l:root !=# ''
          silent let l:output = system(printf(l:command, fnamemodify(l:root, ':p:h')))
        else
          let l:output = ''
        endif
      endif
    endif

    if l:output !=# ''
      if has('iconv') && (&encoding !=# l:encoding)
        let l:output = iconv(l:output, l:encoding, &encoding)
      endif

      break
    endif
  endfor

  if l:output ==# ''
    let l:files = glob(l:path . '**/*', 1, 1)
  else
    let l:files = split(l:output, '\s*\n')
  endif

  "
  if !get(a:context, 'dont_ignore', 0)
    let l:ignore_pattern = get(g:, 'any_listup_source_file_rec_ignore_pattern', '')

    if l:ignore_pattern !=# ''
      if has('win32') || has('win64')
        let l:files = filter(l:files, 'v:val !~? l:ignore_pattern')
      else
        let l:files = filter(l:files, 'v:val !~# l:ignore_pattern')
      endif
    endif
  endif

  return map(l:files, '{ "caption": v:val, "path": v:val }')
endfunction "}}}


"""
function! any_listup#file_rec#register() abort "{{{
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())

  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.file_rec = s:source
endfunction "}}}


let &cpo = s:save_cpo
" vim: foldmethod=marker
