let s:save_cpo = &cpo
set cpo& " vim


let s:header_pattern = '^\(\d\{2,4}.\d\{2,4}.\d\{2,4}\).*$'
let s:item_pattern = '^\s*\* \(.*\):.*$'


"""
function! any_listup#outline#changelog#get_tags(path, start_bufnr, filetype, lines) abort "{{{
  let l:candidates  = []

  for l:index in range(len(a:lines))
    let l:line = a:lines[l:index]
    let l:tokens = matchlist(l:line, s:header_pattern)

    if !empty(l:tokens)
      call add(l:candidates, { 'caption': l:tokens[1],
          \ 'path': a:path, 'bufnr': a:start_bufnr, 'line_nr': l:index + 1 })
    else
      let l:tokens = matchlist(l:line, s:item_pattern)

      if !empty(l:tokens)
        if empty(l:candidates)
          call add(l:candidates, { 'caption': 'yyyy-mm-dd', '__unselectable': 1 })
        endif

        if !has_key(l:candidates[-1], 'children')
          let l:candidates[-1].children = []
        endif

        call add(l:candidates[-1].children, { 'caption': l:tokens[1],
            \ 'path': a:path, 'bufnr': a:start_bufnr, 'line_nr': l:index + 1 })
      endif
    endif
  endfor

  return l:candidates
endfunction "}}}

function! any_listup#outline#changelog#on_syntax() abort "{{{
  syntax match AnyListOutlineChangeLogDate /\d\{4}-\d\{2}-\d\{2}$/
  syntax match AnyListOutlineChangeLogTag /\[[^\]]\+\]/

  hi def link AnyListOutlineChangeLogDate Identifier
  hi def link AnyListOutlineChangeLogTag Comment
endfunction "}}}


let &cpo = s:save_cpo
" vim:ft=vim foldmethod=marker
