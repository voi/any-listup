if exists("b:did_ftplugin")
  finish
endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

" Using line continuation here.
let s:cpo_save = &cpo
set cpo-=C


call any_listup#define_keymap()

if !any_listup#is_default_keymap_disabled()
  call any_listup#define_default_keymap()
endif


let &cpo = s:cpo_save
unlet s:cpo_save
