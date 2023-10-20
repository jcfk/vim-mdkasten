if exists("b:loaded_Mdkasten_ftplugin_markdown")
    finish
endif
let b:loaded_Mdkasten_ftplugin_markdown = 1

command!          MdkFollowLink    call mdkasten#zettelkasten#FollowLink()
command!          MdkOpenBacklink  call mdkasten#zettelkasten#OpenBacklink()
command! -nargs=* MdkSearch        call mdkasten#zettelkasten#Search(<q-args>)
command!          MdkOpenFile      call mdkasten#zettelkasten#OpenFile()
command!          MdkInsertLink    call mdkasten#zettelkasten#InsertLink()
command! -range   MdkInsertLinkFromSelection
                                 \ call mdkasten#zettelkasten#InsertLinkFromSelection()
command! -nargs=1 MdkRename        call mdkasten#zettelkasten#Rename(<q-args>)


