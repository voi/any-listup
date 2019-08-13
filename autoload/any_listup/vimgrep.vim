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
  let a:context.word = input('word >', expand('<cword>'))
  let a:context.pattern = input('extention > ', '*.' . &filetype, 'file')
endfunction "}}}

function! s:source.get_candidates(context) abort "{{{
  if get(a:context, 'word', '') ==# '' ||
      \ get(a:context, 'pattern', '') ==# ''
    return []
  endif

  let l:backup = getqflist()

  try
    call setqflist([], 'r')

    execute printf('silent vimgrep /%s/j %s', a:context.word, a:context.pattern)

    return map(getqflist(), '{
        \   "caption": printf("%s(%d)\t%s", bufname(v:val.bufnr), v:val.lnum, v:val.text),
        \   "path": fnamemodify(bufname(v:val.bufnr), ":p"),
        \   "line_nr": v:val.lnum
        \ }')
  catch
    call setqflist(l:backup, 'r')

    return []
  endtry
endfunction "}}}


"""
function! any_listup#vimgrep#register() abort "{{{
  call extend(s:source.actions, any_listup#action#file_open#get_actions())
  call extend(s:source.actions, any_listup#action#copy_path#get_actions())

  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.vimgrep = s:source
endfunction "}}}


let &cpo = s:save_cpo
