" utils

function s:GetCursorLink()
	let l:cursorcol = col('.')-1
	let l:cursorline = getline('.')
	let l:cursorlinelen = strlen(cursorline)

	let l:linkstart = cursorcol
	while cursorline[linkstart] != '['
		let l:linkstart -= 1
		if linkstart == -1
			return ["", ""]
		endif
	endwhile

	let l:linkend = cursorcol
	while cursorline[linkend] != ']'
		let l:linkend += 1
		if linkend == cursorlinelen
			return ["", ""]
		endif
	endwhile

    let l:link = cursorline[linkstart+1:linkend-1]
    let l:i = 0
    while i < strlen(link)
        if link[i] == '#'
            break
        endif
        let l:i += 1
    endwhile

    return [link[:i-1], link[i:]]
endfunction

function s:IsValidFilename(filename)
    if a:filename !~ '\v^\S*\.md'
        return 0
    endif

    if filereadable(a:filename)
        return 0
    endif

    return 1
endfunction

function s:FileToTitle(link)
    let l:lowercase_title = substitute(a:link[:-4], "-", " ", "g")
    return toupper(lowercase_title[0]) . lowercase_title[1:]
endfunction

function s:OpenBacklink(currentfilename, filename)
    silent execute "e" a:filename "| /\\[" . a:currentfilename
endfunction

function s:OpenSearch(query, filename)
    silent execute "e" a:filename "| /" . a:query
endfunction

function s:InsertLink(filename)
    silent execute "normal i[" . a:filename . "]"
endfunction

" actions

function mdkasten#zettelkasten#InsertLink()
    let l:findcommand = "find . -maxdepth 1 -iname '*.md' -printf '%P\n'"
	call fzf#run(fzf#wrap({
    \ 'options': '--prompt "MdInsertLink> "',
	\ 'source': findcommand, 
	\ 'sink': function("s:InsertLink")
	\ }))
endfunction

function mdkasten#zettelkasten#InsertLinkToSelectedTitle() range
    let [l:bufnum, l:start_lnum, l:start_col, l:off] = getpos("'<")
    let [l:end_lnum, l:end_col] = getpos("'>")[1:2]
    if end_col - 1 == len(getline(end_lnum))
        let l:end_negcol = -1
    else
        let l:end_negcol = end_col - len(getline(end_lnum)) - 1
    endif

    let l:lines = getline(l:start_lnum, l:end_lnum)
    let l:lines[0] = l:lines[0][start_col-1:-1]
    let l:lines[-1] = l:lines[-1][0:end_negcol]

    let l:name = join(lines)
    let name = tolower(name)
    let name = substitute(name, "\\s", "-", "g")
    let name = substitute(name, "[^0-9A-Za-z\-]", "", "g")
    let l:link = name . ".md"
    call setpos('.', [bufnum, end_lnum, end_col, off])
    silent execute "normal a [" . link . "]"
endfunction

function mdkasten#zettelkasten#FollowLink()
    let [l:file, l:header] = s:GetCursorLink()
    if file == ""
        echo "(mdkasten) No link found under cursor."
        return
    endif

	" symlinks
	let l:readlink = system("readlink " . file)
	if readlink != ""
        let l:file = readlink
	endif

    let l:extension = fnamemodify(file, ":e")
    if index(["md", "txt"], extension) >= 0
        if filereadable(file)
            if header == ""
                silent execute "e" file
            else
                silent execute "e" file "| /^" . header
            endif
        else
            execute "edit" file
            execute "normal i# " . s:FileToTitle(file) . "\n\n"
            echo "(mdkasten) New file created."
        endif
    else
        execute "!gloom " . file
    endif
endfunction

function mdkasten#zettelkasten#ShowBacklinks()
    let l:filename = expand('%:t')

	let l:grepcommand = "grep -sl -E \"\\[" . filename . "(\\]|#)\" *.md"
	call fzf#run(fzf#wrap({
    \ 'options': '--prompt "MdBacklinks> "',
	\ 'source': grepcommand, 
	\ 'sink': function("s:OpenBacklink", [filename])
	\ }))
endfunction

function mdkasten#zettelkasten#Search(query)
	let l:grepcommand = "grep -sli -E \"" . a:query . "\" *.md"
	call fzf#run(fzf#wrap({
    \ 'options': '--prompt "MdSearch> "',
	\ 'source': grepcommand, 
	\ 'sink': function("s:OpenSearch", [a:query])
	\ }))
endfunction

function mdkasten#zettelkasten#Rename(newfilename)
    let l:filename = expand('%:t')

    " check validity of new title
    let l:valid = s:IsValidFilename(a:newfilename)
    if valid == 0
        echo "(mdkasten) Invalid filename or already exists."
        return
    endif

    " change all kasten links
    let l:findstr = "\\[" . substitute(filename, "\\.", "\\\\.", "g") . "\\]"
    let l:repstr = a:newfilename
    silent execute "!sed -i \"s/" . findstr . "/[" . repstr . "]/g\" *.md"

    " delete old file
    execute "w " . a:newfilename
    execute "bd"
    silent execute "!rm " . filename

    " open new file
    execute "e " . a:newfilename
    execute "redraw!"

    echo "(mdkasten) Renamed " . filename . " to " . a:newfilename
endfunction
