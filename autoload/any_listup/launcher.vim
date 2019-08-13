let s:save_cpo = &cpo
set cpo& " vim

"""
let s:source = {
    \ 'hooks': {},
    \ 'actions': {},
    \ 'default_action': 'execute',
    \ 'type': 'list',
    \ 'no_multi_select': 1
    \ }


"""
function! s:launcher_get_filepath() abort "{{{
  return fnamemodify(get(g:, 'any_listup_source_launcher_path', '~/.any_listup_launcher'), ':p')
endfunction "}}}

function! s:launcher_parse(line) abort "{{{
  return split(a:line, '\t\+')
endfunction "}}}


"""
function! s:source.get_candidates(context) abort "{{{
  let l:path = s:launcher_get_filepath()
  let l:edit_command = { 'caption': '-- edit --', 'command': 'edit ' . l:path }

  if filereadable(l:path)
    return map(map(readfile(l:path), 's:launcher_parse(v:val)'), '{
        \ "caption": get(v:val, 0, ""), "command": get(v:val, 1, "")
        \ }') + [ l:edit_command ]
  else
    return [ l:edit_command ]
  endif
endfunction "}}}

let s:source.actions.execute = { 'description': 'execute user command' }
function! s:source.actions.execute.do(context, candidates) abort "{{{
  try
    execute get(get(a:candidates, 0, {}), 'command', '')
  catch /.*/
    echomsg v:exception
  endtry
endfunction "}}}


"""
function! any_listup#launcher#register() abort "{{{
  let g:any_listup__sources = get(g:, 'any_listup__sources', {})
  let g:any_listup__sources.launcher = s:source
endfunction "}}}


let &cpo = s:save_cpo
