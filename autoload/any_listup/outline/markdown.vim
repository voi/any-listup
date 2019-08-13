let s:save_cpo = &cpo
set cpo& " vim


"""
function! any_listup#outline#markdown#get_tags(path, start_bufnr, filetype, lines) abort "{{{
  let l:prev_line  = ''
  let l:candidates  = []

  for l:index in range(len(a:lines))
    let l:line = a:lines[l:index]
    let l:tokens = matchlist(l:line, '^\s\{,3}\(#\{1,6}\)\s\?\(.\+\)\%(#\?\s*\)')

    if !empty(l:tokens)
      call add(l:candidates, {
          \ 'caption': substitute(l:tokens[1][1:], '#', '  ', 'g') . l:tokens[2],
          \ 'path': a:path, 'bufnr': a:start_bufnr, 'line_nr': l:index + 1
          \ })

    elseif match(l:prev_line, '^\%(\s\{,3}\)\?\S.\+') >= 0
      if match(l:line, '^\%(\s\{,3}\)\?=\{4,}\s*$') >= 0
        call add(l:candidates, {
            \ 'caption': l:prev_line,
            \ 'path': a:path, 'bufnr': a:start_bufnr, 'line_nr': l:index + 1
            \ })

      elseif match(l:line, '^-\{4,}\s*$') >= 0
        call add(l:candidates, {
            \ 'caption': '  ' . l:prev_line,
            \ 'path': a:path, 'bufnr': a:start_bufnr, 'line_nr': l:index + 1
            \ })

      endif
    endif
  endfor

  return l:candidates
endfunction "}}}


let &cpo = s:save_cpo
" vim:ft=vim foldmethod=marker
