let s:save_cpo = &cpo
set cpo&vim

" ctags default supported language list {{{
"   { filetype : [ language, kinds ]}
let s:supported_langs = {
      \ 'ant':        [ 'ant', 'pt' ],
      \ 'asm':        [ 'asm', 'dlmt' ],
      \ 'asp':        [ 'asp', 'dcfsv' ],
      \ 'awk':        [ 'awk', 'f' ],
      \ 'basic':      [ 'basic', 'cfltvg' ],
      \ 'beta':       [ 'beta', 'fpsv' ],
      \ 'c':          [ 'c', 'cdefglmnpstuvx' ],
      \ 'cpp':        [ 'c++', 'cdefglmnpstuvx' ],
      \ 'cs':         [ 'c#', 'cdeEfgilmnpst' ],
      \ 'cobol':      [ 'cobol', 'dfgpPs' ],
      \ 'dosbatch':   [ 'dosbatch', 'lv' ],
      \ 'eiffel':     [ 'eiffel', 'cfl' ],
      \ 'erlang':     [ 'erlang', 'dfmr' ],
      \ 'flex':       [ 'flex', 'fcmpvx' ],
      \ 'fortran':    [ 'fortran', 'bcefiklLmnpstv' ],
      \ 'html':       [ 'html', 'af' ],
      \ 'java':       [ 'java', 'cefgilmp' ],
      \ 'javascript': [ 'javascript', 'fcmpv' ],
      \ 'lisp':       [ 'lisp', 'f' ],
      \ 'lua':        [ 'lua', 'f' ],
      \ 'make':       [ 'make', 'm' ],
      \ 'matlab':     [ 'matLab', 'f' ],
      \ 'ocaml':      [ 'ocaml', 'cmMvtfCre' ],
      \ 'pascal':     [ 'pascal', 'fp' ],
      \ 'perl':       [ 'perl', 'cflpsd' ],
      \ 'php':        [ 'php', 'cidfvj' ],
      \ 'python':     [ 'python', 'cfmvi' ],
      \ 'rexx':       [ 'rexx', 's' ],
      \ 'ruby':       [ 'ruby', 'cfmF' ],
      \ 'scheme':     [ 'scheme', 'fs' ],
      \ 'sh':         [ 'sh', 'f' ],
      \ 'slang':      [ 'sLang', 'fn' ],
      \ 'sml':        [ 'sml', 'efcsrtv' ],
      \ 'sql':        [ 'sql', 'cdfFlLPprstTvieURDVnxy' ],
      \ 'tcl':        [ 'tcl', 'cmp' ],
      \ 'tex':        [ 'tex', 'csubpPG' ],
      \ 'vera':       [ 'vera', 'cdefglmpPtTvx' ],
      \ 'verilog':    [ 'verilog', 'cefmnprt' ],
      \ 'vhdl':       [ 'vhdl', 'ctTreCdfpPl' ],
      \ 'vim':        [ 'vim', 'acfmv' ],
      \ 'yacc':       [ 'yacc', 'l' ],
      \ }
"}}}

" full-tag name separetor
"   filetype : separetor (default: '.')
let s:delimiters = { 'c': '::', 'cpp': '::' }
"
let s:access_mark = {
    \ 'public': '+ ', 'private': '- ', 'protected': '# ', 'internal': '~ '
    \ }
" 
let s:converters = {
    \ 'c':    function('any_listup#outline#ctags#converter_c_familly'),
    \ 'cpp':  function('any_listup#outline#ctags#converter_c_familly'),
    \ 'cs':   function('any_listup#outline#ctags#converter_c_familly'),
    \ 'java': function('any_listup#outline#ctags#converter_c_familly')
    \ }


function! s:ctags_get_options(filetype) abort "{{{
  let l:user_kinds = get(g:, 'any_listup_source_outline_ctags_kinds', {})

  if has_key(s:supported_langs, a:filetype)
    let [l:lang, l:kind] = s:supported_langs[a:filetype]
    " lang = [ language-name, kinds ]
    return printf(' --language-force=%s --%s-kinds=%s ',
        \ l:lang, l:lang, get(l:user_kinds, l:lang, l:kind))

  else
    let l:lang_map = get(g:, 'any_listup_source_outline_ctags_languages', {})
    let l:lang = get(l:lang_map, a:filetype, '')
    let l:kind = get(l:user_kinds, l:lang, '')

    if l:lang !=# '' && l:kind !=# ''
      return printf(' --language-force=%s --%s-kinds=%s ', l:lang, l:lang, l:kind)
    else
      return ''
    endif
  endif
endfunction "}}}

function! s:ctags_get_taglines(context) abort "{{{
  let l:fname = tempname()

  if has('iconv') && (&encoding !=# &termencoding)
    call writefile(map(a:context.lines, 'iconv(v:val, &encoding, &termencoding)'), l:fname)
  else
    call writefile(a:context.lines, l:fname)
  endif

  " --fields  a  access type
  "           k  tag type (short)
  "           K  tag type (full)
  "           S  signature
  "           s  tag definition scope (namespace)
  "           z  add tag prefix 'kind:'
  let l:command = printf('%s %s --fields=aKSsz -n --verbose=no -u -n -f - %s',
      \ get(g:, 'any_listup_source_outline_ctags_command', 'ctags'),
      \ s:ctags_get_options(a:context.filetype), l:fname)

  let l:taglines = systemlist(l:command)

  call delete(l:fname)

  if has('iconv') && (&encoding !=# &termencoding)
    return map(l:taglines, 'iconv(v:val, &termencoding, &encoding)')
  else
    return l:taglines
  endif
endfunction "}}}

function! s:ctags_parse_tag(line, context) "{{{
  let l:tokens = split(substitute(a:line, '[\n\r]$', '', ''), '\t')

  if len(l:tokens) < 4
    return {}
  endif

  " [basic-format]
  "   tag_name<TAB>file_name<TAB>ex_cmd;"<TAB>extension_fields 
  let l:taginfo = {
      \ 'name': l:tokens[0],
      \ 'kind': '', 'access': '', 'scope': '', 'signature': ''
      \ }
  let l:candidate = {
      \ 'caption': l:tokens[0], '__name': l:tokens[0],
      \ 'path': a:context.path, 'bufnr': a:context.bufnr,
      \ 'line_nr': str2nr(substitute(l:tokens[2], ';"', '', ''))
      \ }

  " [extension_fields]
  "    kind:<TAB>access:<TAB>signature:<TAB>type:full-tag
  for l:token in l:tokens[3:]
    let l:chunks = matchlist(l:token, '^\([^:]\+\):\(.*\)$')

    if !empty(l:chunks)
      if l:chunks[1] ==# 'signature'
        let l:taginfo.signature  = l:chunks[2]
        let l:candidate.caption .= l:chunks[2]

      elseif l:chunks[1] ==# 'access'
        let l:taginfo.access = l:chunks[2]

      elseif l:chunks[1] ==# 'kind'
        let l:taginfo.kind = l:chunks[2]

      else
        let l:taginfo.scope = l:chunks[2]
        let l:candidate.__scope = l:chunks[2]

      endif
    endif
  endfor

  " convert caption
  if has_key(a:context, 'Converter')
    let l:candidate.caption = a:context.Converter(l:taginfo)
  endif

  let l:candidate.__name .= get(l:taginfo, 'signature', '')

  return l:candidate
endfunction "}}}

function! s:ctags_find_element(list, name) abort "{{{
  for l:item in a:list
    if l:item.__name ==# a:name
      return l:item
    endif
  endfor

  return {}
endfunction "}}}

function! s:ctags_build_node(nodelist, tracks, tag) "{{{
  if empty(a:tracks)
    let l:item = s:ctags_find_element(a:nodelist, a:tag.__name)

    if empty(l:item)
      call add(a:nodelist, a:tag)
    else
      if has_key(l:item, '__unselectable')
        call remove(l:item, '__unselectable')
      endif

      call extend(l:item, a:tag)
    endif

  else
    let l:name = remove(a:tracks, 0)
    let l:item = s:ctags_find_element(a:nodelist, l:name)

    if empty(l:item)
      call add(a:nodelist, { 'caption': l:name, '__name': l:name, '__unselectable': 1 })

      let l:item = a:nodelist[-1]
    endif

    if !has_key(l:item, 'children')
      let l:item.children = []
    endif

    call s:ctags_build_node(l:item.children, a:tracks, a:tag)
  endif
endfunction "}}}

function! s:ctags_build_tree(context, tags) "{{{
  let l:candidates = []

  for l:tag in a:tags
    let l:tracks = split(get(l:tag, '__scope', ''), a:context.delim)

    call s:ctags_build_node(l:candidates, l:tracks, l:tag)
  endfor

  return l:candidates
endfunction "}}}


function! any_listup#outline#ctags#converter_c_familly(taginfo) abort "{{{
  if a:taginfo.signature ==# ''
    return printf('%s%s : %s', 
        \ get(s:access_mark, a:taginfo.access, ''),
        \ a:taginfo.name, a:taginfo.kind)
  else
    return printf('%s%s %s', 
        \ get(s:access_mark, a:taginfo.access, ''),
        \ a:taginfo.name, a:taginfo.signature)
  endif
endfunction "}}}

function! any_listup#outline#ctags#get_tags(path, start_bufnr, filetype, lines) abort "{{{
  let l:context = {
      \ 'path': a:path, 'bufnr': a:start_bufnr, 'filetype': a:filetype, 'lines': a:lines,
      \ 'delim': get(s:delimiters, a:filetype, '.'),
      \ }
  let l:converters = extend(s:converters,
      \ get(g:, 'any_listup_source_outline_ctags_converter', {}))

  if has_key(l:converters, a:filetype)
    let l:context.Converter = l:converters[a:filetype]
  endif

  return s:ctags_build_tree(l:context, filter(map(s:ctags_get_taglines(l:context),
      \ 's:ctags_parse_tag(v:val, l:context)'), '!empty(v:val)'))
endfunction "}}}

function! any_listup#outline#ctags#on_syntax_c_familly() abort "{{{
  syntax match AnyListOutlineCAccess / [-+~#] /
  syntax match AnyListOutlineCKind / : \w\+$/

  hi def link AnyListOutlineCAccess Identifier
  hi def link AnyListOutlineCKind SpecialKey
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
" vim: foldmethod=marker
