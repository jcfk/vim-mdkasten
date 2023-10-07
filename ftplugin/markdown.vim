if exists("b:loaded_Mdkasten_ftplugin_markdown")
    finish
endif
let b:loaded_Mdkasten_ftplugin_markdown = 1

command! MdkastenInsertLink
    \ call mdkasten#zettelkasten#InsertLink()
command! -range MdkastenInsertLinkToSelectedTitle
    \ call mdkasten#zettelkasten#InsertLinkToSelectedTitle()
command! MdkastenFollowLink    
    \ call mdkasten#zettelkasten#FollowLink()
command! MdkastenShowBacklinks 
    \ call mdkasten#zettelkasten#ShowBacklinks()
command! -nargs=1 MdkastenSearch
    \ call mdkasten#zettelkasten#Search(<q-args>)
command! -nargs=1 MdkastenRename
    \ call mdkasten#zettelkasten#Rename(<q-args>)
