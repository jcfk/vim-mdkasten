" if exists("b:loaded_Vimdkasten_syntax_markdown")
"     finish
" endif
" let b:loaded_Vimdkasten_syntax_markdown = 1

syntax match TextLink "\v\[/?(.+/){-}[A-Za-z0-9\-]{-}\.md(#+ .{-1,})?\]"
highlight link TextLink String
