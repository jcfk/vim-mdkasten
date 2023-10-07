" if exists("b:loaded_Vimdkasten_syntax_markdown")
"     finish
" endif
" let b:loaded_Vimdkasten_syntax_markdown = 1

syntax match TextLink "\v\[[^\[\]]{-}\.(txt|md)[^\[\]]{-}\]"
highlight link TextLink String
