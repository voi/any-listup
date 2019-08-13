if exists("loaded_any_listup")
  finish
endif

let loaded_any_listup = 1

let any_listup_save_cpo = &cpo
set cpo& " vim


"""
command! -nargs=* -complete=customlist,any_listup#complete_source AnyListup call any_listup#open([<f-args>])


"""
if get(g:, 'any_listup_source_file_rec_default', 0)
  if has('win32') || has('win64')
    let g:any_listup_source_file_rec_commands = extend(get(g:, 'any_listup_source_file_rec_commands', []), [
        \ [ 'FILELIST', 'type %s\FILELIST' ],
        \ [ '', 'dir %s /-N /B /S /A-D' ]
        \])
  else
    let g:any_listup_source_file_rec_commands = extend(get(g:, 'any_listup_source_file_rec_commands', []), [
        \ [ '.FILELIST', 'cat %s/.FILELIST' ],
        \ [ '', 'find %s -type f' ]
        \])
  endif
endif
if get(g:, 'any_listup_source_file_default', 0)
  if has('win32') || has('win64')
    let g:any_listup_source_file_command = 'dir %s /-N /B /S /A-D'
  else
    let g:any_listup_source_file_command = 'find %s -type f'
  endif
endif
if !get(g:, 'any_listup_source_disable_buffer', 0)
  call any_listup#buffer#register()
endif
if !get(g:, 'any_listup_source_disable_clipboard', 0)
  call any_listup#clipboard#register()
endif
if !get(g:, 'any_listup_source_disable_mru', 0)
  call any_listup#mru#register()
endif
if !get(g:, 'any_listup_source_disable_launcher', 0)
  call any_listup#launcher#register()
endif
if !get(g:, 'any_listup_source_disable_sources', 0)
  call any_listup#sources#register()
endif
if !get(g:, 'any_listup_source_disable_outline', 0)
  call any_listup#outline#register()
endif
if !get(g:, 'any_listup_source_disable_file_rec', 0)
  call any_listup#file_rec#register()
endif
if !get(g:, 'any_listup_source_disable_vimgrep', 0)
  call any_listup#vimgrep#register()
endif
if !get(g:, 'any_listup_source_disable_colorscheme', 0)
  call any_listup#colorscheme#register()
endif
if !get(g:, 'any_listup_source_disable_guifont', 0)
  call any_listup#guifont#register()
endif
if !get(g:, 'any_listup_source_disable_mark', 0)
  call any_listup#mark#register()
endif
if !get(g:, 'any_listup_source_disable_register', 0)
  call any_listup#register#register()
endif
if !get(g:, 'any_listup_source_disable_git', 0)
  call any_listup#vcs_git#register()
  call any_listup#vcs_git#make_commands()
endif
if !get(g:, 'any_listup_source_disable_hg', 0)
  call any_listup#vcs_hg#register()
  call any_listup#vcs_hg#make_commands()
endif
if !get(g:, 'any_listup_source_disable_svn', 0)
  call any_listup#vcs_svn#register()
  call any_listup#vcs_svn#make_commands()
endif
if !get(g:, 'any_listup_source_disable_gtags', 0)
  call any_listup#gtags#register()
endif

let &cpo = any_listup_save_cpo
