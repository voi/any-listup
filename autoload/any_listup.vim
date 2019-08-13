"""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim file plugin for editing chalow format file
" Last Change:  2010 Jan 10
" Auther:       voi <kyuvoi1@hotmail.com>
" License:      This file is placed in the public domain.
"
"""""""""""""""""""""""""""""""""""""""""""""""""""
let s:save_cpo = &cpo
set cpo& " vim


"""
let s:source_select_action = {
    \ 'hooks': {},
    \ 'actions': { 'select': {} },
    \ 'default_action': 'select',
    \ 'no_multi_select': 1
    \ }

let s:options = [
    \ '-vertical', '-horizontal', '-tab',
    \ '-no-split', '-no-quit', '-filter',
    \ '-topleft', '-botright',
    \ '-bufname=', '-winsize=', '-adjust-winheight'
    \ ]

let s:filter_keymap = {
    \ 'exit': [ "\<Esc>", "\<C-C>" ],
    \ 'quit': [ "\<C-q>" ],
    \ 'cursor-begin': [ "\<Home>", "\<C-a>" ],
    \ 'cursor-end': [ "\<End>", "\<C-e>" ],
    \ 'cursor-back': [ "\<Left>", "\<C-b>" ],
    \ 'cursor-forward': [ "\<Right>", "\<C-f>" ],
    \ 'delete-char': [ "\<C-h>", "\<BS>" ],
    \ 'enter': [ "\<CR>", "\<C-m>" ],
    \ 'select-action': [ "\<C-i>", "\<Tab>" ],
    \ 'item-down': [ "\<Down>", "\<C-j>" ],
    \ 'item-up': [ "\<Up>", "\<C-k>" ],
    \ 'page-down': [ "\<PageDown>", "\<C-d>" ],
    \ 'page-up': [ "\<PageUp>", "\<C-u>" ],
    \ 'toggle-mark': [ "\<C-Space>" ],
    \ 'clear-word': [ "\<C-g>" ],
    \ }


"""
let s:preset_actions = any_listup#action#word_ope#get_actions()

"""
function! s:source_select_action.actions.select.do(context, candidates) abort "{{{
  let l:model = get(a:context, 'owner_model', {})
  let l:target_candidates = get(a:context, 'candidates', [])

  for l:candidate in a:candidates
    call s:any_listup_do_action(l:model, l:target_candidates, get(l:candidate, 'action_name', ''))
  endfor

  let a:context.is_done_action = 1
endfunction "}}}

function! s:source_select_action.get_candidates(context) abort "{{{
  let l:model = get(a:context, 'owner_model', {})

  if empty(l:model)
    return []
  endif

  " get candidates
  let l:source = get(l:model, 'source', {})
  let l:actions = items(s:preset_actions) + items(get(l:source, 'actions', {}))
  let l:format = printf('%%-%ds- %%s', max(map(copy(l:actions), 'len(v:val[0])')) + 4)

  return sort(map(l:actions, '{
      \   "caption": printf(l:format, v:val[0], get(v:val[1], "description", "")),
      \   "action_name": v:val[0]
      \ }'),
      \ { one, oth ->
      \   ( one.caption ==# oth.caption ? 0 : ( one.caption ># oth.caption ? 1 : -1 ) )
      \ } )
endfunction

function! s:source_select_action.on_close(context) abort "{{{
  if get(a:context, 'is_done_action', 0)
    let l:owner_model = get(a:context, 'owner_model', {})

    if has_key(l:owner_model, 'bufnr')
      execute 'bwipeout! ' . l:model.bufnr
    endif
  endif
endfunction "}}}


"""
function! s:any_listup_get_source(name) abort "{{{
  return get(get(g:, 'any_listup__sources', {}), a:name, {})
endfunction "}}}

function! s:any_listup_parse_source_name(cmdline) abort "{{{
  let l:cmdline = substitute(a:cmdline, '"[^"]\*"', '', 'g')
  let l:cmdline = substitute(l:cmdline, "'[^']\*'", '', 'g')
  let l:cmdline = substitute(l:cmdline, '\\\s', '_', 'g')
  let l:cmdline = substitute(l:cmdline, '[-@]\S\+', '', 'g')
  let l:cmdline = substitute(l:cmdline, 'AnyListup', '', '')

  let l:name = get(split(substitute(l:cmdline, '^\s\*\|\s\*$', '', 'g'), '\s\+'), 0, '')

  echomsg l:name
  return l:name
endfunction "}}}

function! s:any_listup_set_option(options, name, value) abort "{{{
  if a:name ==# 'no-split'
    let a:options.direction = ''
    let a:options.open_method = 'enew'

  elseif a:name ==# 'vertical'
    let a:options.direction = 'vertical'
    let a:options.open_method = 'new'

  elseif a:name ==# 'horizontal'
    let a:options.direction = ''
    let a:options.open_method = 'new'

  elseif a:name ==# 'tab'
    let a:options.direction = ''
    let a:options.open_method = 'tabnew'

  elseif a:name ==# 'no-quit'
    let a:options.no_quit = 1

  elseif a:name ==# 'topleft'
    let a:options.layout = a:name

  elseif a:name ==# 'botright'
    let a:options.layout = a:name

  elseif a:name ==# 'bufname'
    let a:options.buf_name = a:value

  elseif a:name ==# 'winsize'
    let a:options.winsize = max([str2nr(a:value), 1])

  elseif a:name ==# 'filter'
    let a:options.filter_mode = 1

  elseif a:name ==# 'adjust-winheight'
    let a:options.adjust_winheight = 1

  endif

  return a:options
endfunction "}}}

function! s:any_listup_parse_arguments(arguments) abort "{{{
  let l:options = {}
  let l:params = {}
  let l:name = ''

  for l:arg in a:arguments
    " argument of source?
    let l:tokens = matchlist(l:arg, '^-\([^= \t]\+\)\%(=\(.*\)\?\)\?$')

    if empty(l:tokens)
      " arguments of model?
      let l:tokens = matchlist(l:arg, '^@\([^= \t]\+\)\%(=\(.*\)\?\)\?$')

      if empty(l:tokens)
        " source name?
        let l:name = l:arg

      else
        let l:value = l:tokens[2]
        let l:value =substitute(l:value, '"\([^"]\+\)"', '\1', '')
        let l:value =substitute(l:value, "'\([^']\+\)'", '\1', '')

        let l:params[l:tokens[1]] = l:value
      endif

    else
      let l:value = l:tokens[2]
      let l:value =substitute(l:value, '"\([^"]\+\)"', '\1', '')
      let l:value =substitute(l:value, "'\([^']\+\)'", '\1', '')

      let l:options = s:any_listup_set_option(l:options, l:tokens[1], l:value)

    endif
  endfor

  return [l:options, l:name, l:params]
endfunction "}}}


function! s:any_listup_do_action(model, candidates, action_name) abort "{{{
  if empty(a:candidates)
    return
  endif

  if !s:model_get_option(a:model, 'no_quit', 0)
    call s:buffer_close(a:model)
  endif

  if has_key(a:model.source.actions, a:action_name)
    call a:model.source.actions[a:action_name].do(a:model.context, a:candidates)
  else
    call s:preset_actions[a:action_name].do(a:model.context, a:candidates)
  endif
endfunction "}}}

function! s:any_listup_gather_candidates(model) abort "{{{
  if type(get(a:model.source, 'get_candidates', '')) != type(function('tr'))
    return 0
  endif

  let l:candidates = a:model.source.get_candidates(a:model.context)

  if get(a:model.source, 'type', 'list') ==# 'tree'
    let l:candidates = s:candidate_flatton(l:candidates, 0)
  endif

  call s:model_set_candidates(a:model, l:candidates)
  call s:model_apply_converter(a:model)

  return !empty(s:model_get_candidates(a:model))
endfunction "}}}

function! s:any_listup_display_candidates(model) abort "{{{
  let l:candidates = s:model_get_candidates(a:model)

  " 
  call s:buffer_draw_candidates(l:candidates)

  if s:model_get_option(a:model, 'open_method', 'new') !=# 'enew'
    call s:window_adjust_height(a:model, l:candidates)
  endif
endfunction "}}}

function! s:any_listup_get_current_model() abort "{{{
  let l:model = get(b:, 'model', {})

  if !has_key(l:model, 'source')     || !has_key(l:model, 'source_name') ||
      \ !has_key(l:model, 'context')    || !has_key(l:model, 'options')     ||
      \ !has_key(l:model, 'candidates') || !has_key(l:model, 'filtered_candidates')
    return {}
  endif

  return l:model
endfunction "}}}

function! s:any_listup_default_converter(candidate) abort "{{{
  return get(a:candidate, 'caption', string(a:candidate))
endfunction "}}}

function! s:any_listup_get_filter_key_command(key_char) abort "{{{
  for [ l:name, l:keys ] in items(get(g:, 'any_listup__filter_keymap', s:filter_keymap))
    if index(l:keys, a:key_char) >= 0
      return l:name
    endif
  endfor

  return ''
endfunction "}}}

function! s:any_listup_do_filter_keymap(filter_context, key_nr, key_char) abort "{{{
  let l:command = s:any_listup_get_filter_key_command(a:key_char)

  if l:command ==# 'exit'
    return 1

  elseif l:command ==# 'quit'
    let a:filter_context.is_quit = 1

    return 1

  elseif l:command ==# 'cursor-begin'
    let a:filter_context.curr_index = 0

  elseif l:command ==# 'cursor-end'
    let a:filter_context.curr_index = len(a:filter_context.curr_word)

  elseif l:command ==# 'cursor-back'
    if a:filter_context.curr_index > 0
      let a:filter_context.curr_index -= 1
    endif

  elseif l:command ==# 'cursor-forward'
    if a:filter_context.curr_index < len(a:filter_context.curr_word)
      let a:filter_context.curr_index += 1
    endif

  elseif l:command ==# 'delete-char'
    if len(a:filter_context.curr_word) > 0 &&
        \ a:filter_context.curr_index > 0
      let l:word = a:filter_context.curr_word
      let l:curr_index = a:filter_context.curr_index

      let a:filter_context.curr_word = strpart(l:word, 0, l:curr_index - 1) .
          \ strpart(l:word, l:curr_index)
      let a:filter_context.curr_index -= 1
      let a:filter_context.is_changed = 1
    endif

  elseif l:command ==# 'enter'
    call s:do_default_action()

    return 1

  elseif l:command ==# 'select-action'
    call s:do_selected_action()

    return 1

  elseif l:command ==# 'item-down'
    let l:curpos = getpos('.')
    let l:count = s:model_get_candidates_count(a:filter_context.model)

    call cursor(( ( l:curpos[1] - 1 + 1 ) % l:count ) + 1, l:curpos[2])

  elseif l:command ==# 'item-up'
    let l:curpos = getpos('.')
    let l:count = s:model_get_candidates_count(a:filter_context.model)

    call cursor(( ( l:curpos[1] - 1 - 1 + l:count ) % l:count ) + 1, l:curpos[2])

  elseif l:command ==# 'page-down'
    let l:curpos = getpos('.')
    let l:count = s:model_get_candidates_count(a:filter_context.model)

    call cursor(( ( l:curpos[1] - 1 + winheight(0) + l:count ) % l:count ) + 1, l:curpos[2])

  elseif l:command ==# 'page-up'
    let l:curpos = getpos('.')
    let l:count = s:model_get_candidates_count(a:filter_context.model)

    call cursor(( ( l:curpos[1] - 1 - winheight(0) + l:count ) % l:count ) + 1, l:curpos[2])

  elseif l:command ==# 'toggle-mark'
    call s:toggle_mark('')

  elseif l:command ==# 'clear-word'
    let a:filter_context.curr_word = ''
    let a:filter_context.is_changed = 1

  endif

  return 0
endfunction "}}}


function! s:buffer_redraw_candidate(candidate) abort "{{{
  " unlock buffer
  silent! setlocal noreadonly modifiable

  call setline('.', s:candidate_to_string(a:candidate))

  " lock buffer
  silent! setlocal readonly nomodifiable
endfunction "}}}

function! s:buffer_draw_candidates(candidates) abort "{{{
  " unlock buffer
  silent! setlocal noreadonly modifiable

  let l:pos = getcurpos()

  execute 'silent! %delete_'

  call append(1, map(copy(a:candidates), 's:candidate_to_string(v:val)'))

  execute 'silent! 1delete _'

  call setpos('.', l:pos)

  " lock buffer
  silent! setlocal readonly nomodifiable
endfunction "}}}

function! s:buffer_create(model, options) abort "{{{
  let l:open_method = get(a:options, 'open_method', 'new')
  let l:direction = get(a:options, 'direction', '')

  if l:open_method ==# 'new' || l:open_method ==# 'vnew'
    if l:direction ==# ''
      let l:open_method = get(a:options, 'winsize', s:window_default_height()) . l:open_method

    else
      let l:open_method = get(a:options, 'winsize', s:window_default_width()) . l:open_method

    endif
  endif

  let l:buf_name = get(a:options, 'bufname', '')
  let l:layout = get(a:options, 'layout', 'topleft')

  if l:buf_name !=# ''
    let l:winnr = bufwinnr(l:buf_name)

    if l:winnr > 0
      execute l:winnr . 'wincmd w'

      return s:any_listup_get_current_model()

    else
      let l:bufnr = bufnr(l:buf_name)

      if l:bufnr > 0
        execute printf('noautocmd silent! %s %dsplit %s', l:layout, l:winsize, l:buf_name)

      else
        execute printf('noautocmd silent! %s %s %s', l:direction, l:layout, l:open_method)

      endif
    endif
  else
    execute printf('noautocmd silent! %s %s %s', l:direction, l:layout, l:open_method)

  endif

  let b:model = extend(a:model, { 'bufnr': bufnr('%') })

  " buffer option
  silent! setlocal filetype=any_listup buftype=nofile bufhidden=hide
  silent! setlocal noswapfile nowrap nonumber
  silent! setlocal nolist nobuflisted
  silent! setlocal winfixwidth winfixheight

  " buffer autocmd
  doautocmd BufEnter,BufWinEnter

  return b:model
endfunction "}}}

function! s:buffer_close(model) abort "{{{
  let l:source = a:model.source

  if s:source_has_hook(l:source, 'on_close')
    call l:source.hooks.on_close(get(a:model, 'context', {}))
  endif

  if s:model_get_option(a:model, 'open_method', 'new') !=# 'enew'
    if tabpagewinnr(tabpagenr(), '$') > 1
      execute 'wincmd p'
    endif
  endif

  if has_key(a:model, 'bufnr')
    execute 'bwipeout! ' . a:model.bufnr
  endif

  redrawstatus!
endfunction "}}}


function! s:window_default_height() abort "{{{
  return &lines / 3
endfunction "}}}

function! s:window_default_width() abort "{{{
  return &columns / 4
endfunction "}}}

function! s:window_adjust_height(model, candidates) abort "{{{
  if s:model_is_adjust_winheight(a:model) &&
      \ s:model_get_option(a:model, 'direction', '') ==# ''
    execute 'resize ' . max([ 1, min([ len(a:candidates), s:window_default_height() ]) ])
  endif
endfunction "}}}


function! s:model_create(source, name, context, options) abort "{{{
    return {
        \ 'source': a:source, 'source_name': a:name,
        \ 'context': a:context, 'options': a:options,
        \ 'candidates': [], 'filtered_candidates': []
        \ }
endfunction "}}}

function! s:model_get_option(model, name, default) abort "{{{
  return get(get(a:model, 'options', {}), a:name, a:default)
endfunction "}}}

function! s:model_can_multi_select(model) abort "{{{
  return !get(a:model.source, 'no_multi_select', 0)
endfunction "}}}

function! s:model_set_candidates(model, candidates) abort "{{{
  let a:model.candidates = a:candidates
  let a:model.filtered_candidates = a:candidates
endfunction "}}}

function! s:model_get_candidates(model) abort "{{{
  return get(a:model, 'filtered_candidates', [])
endfunction "}}}

function! s:model_get_candidates_count(model) abort "{{{
  return len(s:model_get_candidates(a:model))
endfunction "}}}

function! s:model_get_current_candidate(model) abort "{{{
  let l:candidate = get(s:model_get_candidates(a:model), line('.') - 1, {})

  if get(l:candidate, '__unselectable', 0)
    return {}
  else

  return l:candidate
endfunction "}}}

function! s:model_get_selected_candidates(model) abort "{{{
  if get(a:model, 'marked_count', 0) > 0
    return filter(copy(s:model_get_candidates(a:model)),
        \ 'get(v:val, "__marked", 0) && !get(v:val, "__unselectable", 0)')
  else
    let l:candidate = s:model_get_current_candidate(a:model)

    if empty(l:candidate)
      return []
    else
      return [ l:candidate ]
    endif
  endif
endfunction "}}}

function! s:model_filter_candidates(model, pattern) abort "{{{
  let a:model.filtered_candidates = filter(copy(a:model.candidates),
      \ 'get(v:val, "caption", "") =~ a:pattern')
  let a:model.filter_word = a:pattern

  return a:model.filtered_candidates
endfunction "}}}

function! s:model_get_handler(model, name) abort "{{{
  let l:handler = get(get(g:, 'any_listup__handlers', {}), a:model.source_name, {})

  if type(get(l:handler, a:name, '')) ==# type(function('tr'))
    return l:handler
  else
    return {}
  endif
endfunction "}}}

function! s:model_apply_converter(model) abort "{{{
  let l:handler = s:model_get_handler(a:model, 'converter')

  if empty(l:handler)
    return
  endif

  call map(get(a:model, 'candidates', []), 's:candidate_apply_converter(v:val, l:handler)')
endfunction "}}}

function! s:model_is_adjust_winheight(model) abort "{{{
  return s:model_get_option(a:model, 'adjust_winheight', 
      \ get(g:, 'any_listup__winheight_adjust_candidates', 0))
endfunction "}}}


function! s:source_has_hook(source, name) abort "{{{
  return has_key(get(a:source, 'hooks', {}), a:name) && 
      \ type(a:source.hooks[a:name]) == type(function('tr'))
endfunction "}}}

function! s:source_has_action(source, action_name) abort "{{{
  if a:action_name ==# ''
    return 0
  endif

  let l:actions = extend(copy(s:preset_actions), get(a:source, 'actions', {}))

  if !has_key(get(l:actions, a:action_name, {}), 'do')
    return 0
  endif

  return (type(l:actions[a:action_name].do) == type(function('tr')))
endfunction "}}}

function! s:source_get_default_action(source) abort "{{{
  if has_key(a:source, 'default_action')
    if !s:source_has_action(a:source, a:source.default_action)
      return ''
    endif

    return a:source.default_action

  else
    let l:action_names = keys(get(a:source, 'actions', {}))

    if len(l:action_names) != 1
      return ''
    endif

    return get(l:action_names[0], 'action_name', '')

  endif
endfunction "}}}

function! s:candidate_flatton(candidates, depth) abort "{{{
  let l:array = []

  for l:candidate in a:candidates
    let l:candidate.__depth = a:depth

    call add(l:array, l:candidate)
    call extend(l:array, s:candidate_flatton(get(l:candidate, 'children', []), a:depth + 1))
  endfor

  return l:array
endfunction "}}}

function! s:candidate_to_string(candidate) abort "{{{
  let l:indent = repeat('  ', get(a:candidate, '__depth', 0))

  if type(a:candidate) == type({})
    return printf('%s%s %s',
        \ get(a:candidate, '__marked', 0) ? '*' : ' ',
        \ l:indent,
        \ get(a:candidate, 'caption', ''))

  else
    return l:indent . string(a:candidate)

  endif
endfunction "}}}

function! s:candidate_apply_converter(candidate, handler) abort "{{{
  let a:candidate.caption = a:handler.converter(a:candidate)

  return a:candidate
endfunction "}}}


function! s:toggle_mark(key) abort "{{{
  let l:model = s:any_listup_get_current_model()

  if s:model_can_multi_select(l:model)
    let l:candidate = s:model_get_current_candidate(l:model)

    if !empty(l:candidate)
      let l:candidate.__marked  = !get(l:candidate, '__marked', 0)
      let l:model.marked_count  = get(l:model, 'marked_count', 0)
      let l:model.marked_count += (l:candidate.__marked ? 1 : -1)

      call s:buffer_redraw_candidate(l:candidate)
    endif
  endif

  if a:key ==# 'j' || a:key ==# 'k'
    execute 'normal ' . a:key
  endif
endfunction "}}}

function! s:reset_all_marks(flag) abort "{{{
  let l:model = s:any_listup_get_current_model()

  if !s:model_can_multi_select(l:model)
    return 
  endif

  let l:candidates = s:model_get_selected_candidates(l:model)

  if !empty(l:candidates)
    for l:candidate in l:candidates
      if a:flag < 0
        let l:candidate.__marked = !get(v:val, '__marked', 0)
      else
        let l:candidate.__marked = a:flag
      endif
    endfor

    call s:buffer_draw_candidates(l:candidates)
  endif
endfunction "}}}

function! s:do_default_action() abort "{{{
  let l:model = s:any_listup_get_current_model()
  let l:action_name = s:source_get_default_action(l:model.source)

  if l:action_name ==# ''
    echomsg printf('source "%s" has no default action', l:model.source_name)
    return
  endif

  let l:candidates = s:model_get_selected_candidates(l:model)

  call s:any_listup_do_action(l:model, l:candidates, l:action_name)
endfunction "}}}

function! s:do_selected_action() abort "{{{
  let l:model = s:any_listup_get_current_model()

  " if source has only one action, do it.
  if len(get(l:model.source, 'actions', {})) == 1
    call s:do_default_action()

  else
    let l:actions_model = s:model_create(
        \ s:source_select_action, 'action-select',
        \ { 'owner_model': l:model, 'candidates': s:model_get_selected_candidates(l:model) },
        \ {} )

    if !s:any_listup_gather_candidates(l:actions_model)
      echomsg 'any-listup: NO CANDIDATES!!'

      return
    endif

    let l:actions_model = s:buffer_create(l:actions_model, { 'open_method': 'enew' })

    "
    call s:any_listup_display_candidates(l:actions_model)

    if s:model_get_option(l:model, 'filter_mode', 0)
      redraw

      call s:start_filtering()
    endif
  endif
endfunction "}}}

function! s:redraw_candidates() abort "{{{
  let l:model = s:any_listup_get_current_model()

  if !s:any_listup_gather_candidates(l:model)
    echomsg 'any-listup: NO CANDIDATES!!'
  endif

  call s:any_listup_display_candidates(l:model)
endfunction "}}}

function! s:close() abort "{{{
  call s:buffer_close(s:any_listup_get_current_model())
endfunction "}}}

function! s:show_cmdline(context) abort "{{{
  let l:word = a:context.curr_word
  let l:index = a:context.curr_index

  if l:index >= len(l:word)
    echohl Normal | echon '>> ' . l:word | 
        \ echohl Cursor | echon '_' | 
        \ echohl Normal
  else
    echohl Normal | echon '>> ' . strpart(l:word, 0, l:index) | 
        \ echohl Cursor | echon strpart(l:word, l:index, 1) | 
        \ echohl Normal | echon strpart(l:word, l:index + 1)
  endif

  redraw
endfunction "}}}

function! s:do_filtering(filter_context) abort "{{{
  let a:filter_context.is_changed = 0
  let l:key_nr = getchar()
  let l:key_char = type(l:key_nr) == type(0) ? nr2char(l:key_nr) : l:key_nr

  if !and(l:key_nr, 0x80) && l:key_nr >=# 0x20
    let l:word = a:filter_context.curr_word
    let l:curr_index = a:filter_context.curr_index

    let a:filter_context.curr_word = strpart(l:word, 0, l:curr_index) .
        \ l:key_char . strpart(l:word, l:curr_index)
    let a:filter_context.curr_index += 1
    let a:filter_context.is_changed = 1


  else
    if s:any_listup_do_filter_keymap(a:filter_context, l:key_nr, l:key_char)
      return 1
    endif
  endif

  if a:filter_context.is_changed && 
      \ a:filter_context.curr_word != a:filter_context.prev_word

    call s:buffer_draw_candidates(
        \ s:model_filter_candidates(
        \     a:filter_context.model,
        \     a:filter_context.curr_word
        \ ))

    let a:filter_context.prev_word = a:filter_context.curr_word
  endif

  setlocal cursorline

  call s:show_cmdline(a:filter_context)

  return 0
endfunction "}}}

function! s:make_filter_context(model) abort "{{{
  let l:word = get(a:model, 'filter_word', '')

  return {
      \ 'model': a:model, 'source': a:model.source,
      \ 'curr_word': l:word, 'prev_word': l:word,
      \ 'curr_index': len(l:word)
      \ }
endfunction "}}}

function! s:start_filtering() abort "{{{
  let l:filter_context = s:make_filter_context(s:any_listup_get_current_model())
  let l:cursorline = &cursorline
  let l:guicursor = &guicursor
  let l:t_ve = &t_ve

  set guicursor=n:block-NONE
  set t_ve=
  setlocal cursorline

  call s:show_cmdline(l:filter_context)

  try
    while 1
      if s:do_filtering(l:filter_context)
        break
      endif
    endwhile
  catch /.*/
    echomsg 'catch' v:exception
  endtry

  let &guicursor = l:guicursor
  let &t_ve = l:t_ve

  if !l:cursorline
    setlocal nocursorline
  endif

  echo '' | redraw | redrawstatus

  if get(l:filter_context, 'is_quit', 0)
    call s:close()
  endif
endfunction "}}}


function! any_listup#open(arguments) abort "{{{
  let [l:options, l:name, l:params] = s:any_listup_parse_arguments(a:arguments)

  " 
  let l:source = s:any_listup_get_source(l:name)

  if empty(l:source)
    echomsg printf('source "%s" is not exist.', l:name)

    return
  endif

  " 
  let l:context = {}

  if s:source_has_hook(l:source, 'on_ready')
    call l:source.hooks.on_ready(l:context, l:params)
  endif

  " 
  let l:model = s:model_create(l:source, l:name, l:context, l:options)

  if !s:any_listup_gather_candidates(l:model)
    echomsg 'any-listup: NO CANDIDATES!!'

    return
  endif

  " 
  let l:model = s:buffer_create(l:model, l:options)

  if s:source_has_hook(l:source, 'on_init')
    call l:source.hooks.on_init(l:context, l:params)
  endif

  " 
  let l:handler = s:model_get_handler(l:model, 'on_syntax')

  if !empty(l:handler)
    call l:handler.on_syntax()
  endif

  "
  call s:any_listup_display_candidates(l:model)

  if s:model_get_option(l:model, 'filter_mode', 0)
    redraw

    call s:start_filtering()
  endif
endfunction "}}}

function! any_listup#do_specified_action(action_name) abort "{{{
  let l:model = s:any_listup_get_current_model()

  if empty(l:model)
    return
  endif

  if !s:source_has_action(l:model.source, a:action_name)
    echomsg printf('source "%s" has no "%s" action', l:model.source_name, a:action_name)
    return
  endif

  let l:candidates = s:model_get_selected_candidates(l:model)

  call s:any_listup_do_action(l:model, l:candidates, a:action_name)
endfunction "}}}

function! any_listup#complete_source(argLead, cmdLine, cursorPos) abort "{{{
  let l:pattern = '^' . a:argLead

  if a:argLead =~# '^-'
    return filter(s:options, 'v:val =~# l:pattern')

  elseif a:argLead =~# '^@'
    let l:source = s:any_listup_get_source(s:any_listup_parse_source_name(a:cmdLine))

    if s:source_has_hook(l:source, 'on_complete')
      return l:source.hooks.on_complete(a:argLead)
    endif

  else
    return filter(keys(get(g:, 'any_listup__sources', {})), 'v:val =~# l:pattern')

  endif

  return []
endfunction "}}}

function! any_listup#is_default_keymap_disabled() abort "{{{
  return get(g:, 'any_listup__disable_default_keymap', 0)
endfunction "}}}

function! any_listup#define_keymap() abort "{{{
  nnoremap <silent> <buffer> <Plug>(any_listup_close)
      \ :<C-u>call <SID>close()<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_force_radraw)
      \ :<C-u>call <SID>redraw_candidates()<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_yank)
      \ :<C-u>call any_listup#do_specified_action('yank')<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_echo)
      \ :<C-u>call any_listup#do_specified_action('echo')<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_toggle_down)
      \ :<C-u>call <SID>toggle_mark('j')<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_toggle_up)
      \ :<C-u>call <SID>toggle_mark('k')<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_do_default_action)
      \ :<C-u>call <SID>do_default_action()<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_do_selected_action)
      \ :<C-u>call <SID>do_selected_action()<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_start_filtering)
      \ :<C-u>call <SID>start_filtering()<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_select_all)
      \ :<C-u>call <SID>reset_all_marks(1)<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_unselect_all)
      \ :<C-u>call <SID>reset_all_marks(0)<CR>
  nnoremap <silent> <buffer> <Plug>(any_listup_toggle_all)
      \ :<C-u>call <SID>reset_all_marks(-1)<CR>
endfunction "}}}

function! any_listup#define_default_keymap() abort "{{{
  nmap <silent> <buffer> q         <Plug>(any_listup_close)
  nmap <silent> <buffer> u         <Plug>(any_listup_force_radraw)
  nmap <silent> <buffer> y         <Plug>(any_listup_yank)
  nmap <silent> <buffer> <C-e>     <Plug>(any_listup_echo)
  nmap <silent> <buffer> <Space>   <Plug>(any_listup_toggle_down)
  nmap <silent> <buffer> <S-Space> <Plug>(any_listup_toggle_up)
  nmap <silent> <buffer> <CR>      <Plug>(any_listup_do_default_action)
  nmap <silent> <buffer> a         <Plug>(any_listup_do_selected_action)
  nmap <silent> <buffer> i         <Plug>(any_listup_start_filtering)
  nmap <silent> <buffer> +         <Plug>(any_listup_select_all)
  nmap <silent> <buffer> -         <Plug>(any_listup_unselect_all)
  nmap <silent> <buffer> @         <Plug>(any_listup_toggle_all)
endfunction "}}}


let &cpo = s:save_cpo
" vim:foldmethod=marker
