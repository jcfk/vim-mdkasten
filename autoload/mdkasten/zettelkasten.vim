" utils

function s:GetKastenRoot()
    let l:cwd = split(expand("%:p:h"), "/")
    let l:i = 1
    while i <= len(cwd)
        if isdirectory("/" . join(cwd[:-i], "/") . "/.mdkasten")
            return "/" . join(cwd[:-i], "/")
        endif
        let i += 1
    endwhile
    return 0
endfunction

function s:MakeFindOptions() " listing exactly the zettelkasten files
    " root
    let l:root = s:GetKastenRoot()
    let l:ret = root

    " ignore
    let l:ignorelist = []
    for line in readfile(root."/.mdkasten/prune")
        call add(ignorelist, "-path \"".root."/".line."\"")
    endfor
    let l:ret .= " -type d \\( ".join(ignorelist, " -o ")." \\) -prune"

    " iname
    let l:ret .= " -o -iname '*.md'"

    return ret
endfunction

function s:ParseLink(link)
    let l:i = 0
    while i < strlen(a:link)
        if a:link[i] == '#'
            break
        endif
        let l:i += 1
    endwhile

    " [link path, link header]
    return [a:link[:i-1], a:link[i:]]
endfunction

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
    return s:ParseLink(link)
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
    let l:ret = substitute(split(a:link[:-4], "/")[-1], "-", " ", "g")
    return toupper(l:ret[0]) . l:ret[1:]
endfunction

function s:OpenBacklink(currentfilename, filename)
    call s:OpenSearch("\\[\\(.*\\/\\)*".a:currentfilename."\\(#\\|\\]\\)", a:filename)
endfunction

function s:OpenSearch(query, filename)
    silent execute "e" s:GetKastenRoot()."/".a:filename "| /".a:query
endfunction

function s:OpenSearchRg(line)
    let l:components = split(a:line, ":")
    let l:filepath = components[0]
    let l:linenum = components[1]
    silent execute "e" s:GetKastenRoot().filepath "| :".linenum
endfunction

function s:InsertLink(filename)
    silent execute "normal i[/" . a:filename . "]"
endfunction

" actions

function mdkasten#zettelkasten#OpenFile()
    let l:source = "find ".s:MakeFindOptions()." -printf '%P\n'"
	call fzf#run(fzf#wrap({
        \ 'options': ["--prompt", "MdkOpenFile> "],
        \ 'source': source, 
        \ 'sink': "e"
        \ }))
endfunction

function mdkasten#zettelkasten#InsertLink()
    let l:source = "find ".s:MakeFindOptions()." -printf '%P\n'"
	call fzf#run(fzf#wrap({
        \ 'options': ["--prompt", "MdkInsertLink> "],
        \ 'source': source, 
        \ 'sink': function("s:InsertLink")
        \ }))
endfunction

function mdkasten#zettelkasten#InsertLinkFromSelection() range
    let [l:bufnum, l:startlnum, l:startcol, l:off] = getpos("'<")
    let [l:endlnum, l:endcol] = getpos("'>")[1:2]
    if endcol - 1 == len(getline(endlnum))
        let l:endnegcol = -1
    else
        let l:endnegcol = endcol - len(getline(endlnum)) - 1
    endif

    let l:lines = getline(l:startlnum, l:endlnum)
    let l:lines[0] = l:lines[0][startcol-1:-1]
    let l:lines[-1] = l:lines[-1][0:endnegcol]

    let l:name = join(lines)
    let name = tolower(name)
    let name = substitute(name, "\\s", "-", "g")
    let name = substitute(name, "[^0-9A-Za-z\-]", "", "g")
    let l:link = name . ".md"
    call setpos('.', [bufnum, endlnum, endcol, off])
    silent execute "normal a [" . link . "]"
endfunction

function mdkasten#zettelkasten#FollowLink()
    let [l:file, l:header] = s:GetCursorLink()
    if len(file) == 0
        echo "(mdkasten) No link found under cursor."
        return
    endif

    " kasten-absolute paths
    if file[0] == "/"
        let l:file = s:GetKastenRoot() . file
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

function mdkasten#zettelkasten#OpenBacklink()
    let l:filename = expand('%:t')
	let l:source = "find ".s:MakeFindOptions()." -print0".
        \ " | xargs -0 grep -sl -E '\\[/?(.+/)*".filename."(\\]|#+ .+\\])'".
        \ " | cut -c ".(len(s:GetKastenRoot())+1)."-"
	call fzf#run(fzf#wrap({
        \ 'options': ["--prompt", "MdkOpenBacklink> "],
        \ 'source': source, 
        \ 'sink': function("s:OpenBacklink", [filename])
        \ }))
endfunction

function mdkasten#zettelkasten#Search(query)
    if len(a:query)
        let l:source = "find ".s:MakeFindOptions()." -print0".
            \ " | xargs -0 grep -sli -E \"".a:query."\"".
            \ " | sed 's+".s:GetKastenRoot()."++g'"
        call fzf#run(fzf#wrap({
            \ 'options': ["--prompt", "MdkSearch> "],
            \ 'source': source, 
            \ 'sink': function("s:OpenSearch", [a:query])
            \ }))
    else
        let l:source = "find ".s:MakeFindOptions()." -print0".
            \ " | xargs -0 rg --line-number --color=always --smart-case ''".
            \ " | sed 's+".s:GetKastenRoot()."++g'"
        call fzf#run(fzf#wrap({
            \ "options": ["--exact", "--color", "hl:9:bold", "--ansi",
                \ "--prompt", "MdkSearch> ", "--delimiter", ":",
                \ "--nth", "3.."],
            \ "source": source,
            \ "sink": function("s:OpenSearchRg")
            \ }))
    endif
endfunction

function mdkasten#zettelkasten#Rename(newfilename)
    let l:root = s:GetKastenRoot()
    let l:curfilename = expand('%:t')
    let l:curfilepath = expand('%:p')[len(root):]

    " check validity of new title
    if a:newfilename !~ '\v^\S*\.md'
        echo "(mdkasten) Invalid filename."
        return
    endif
    if filereadable(a:newfilename)
        echo "(mdkasten) File already exists."
        return
    endif

    " change all kasten links
    let l:findoutput = systemlist("find ".s:MakeFindOptions()." -print0".
        \ " | xargs -0 grep -so -E '\\[/?(.+/)*".curfilename."(\\]|#+ .+\\])'".
        \ " | cut -c ".(len(s:GetKastenRoot())+1)."-")
    for line in findoutput
        let [l:fpath, l:backlink] = split(line, ":")
        let [l:backlinkpath, l:backlinkheader] = s:ParseLink(backlink[1:-2])

        if backlinkpath[0] == "/"
            let l:backlinkpathabs = backlinkpath
        else
            let l:backlinkpathabs = "/".systemlist('realpath --relative-base '.root.
                \ ' "'.root.fnamemodify(fpath, ":h").'/'.backlinkpath.'"')[0]
        endif

        if backlinkpathabs == curfilepath
            let l:backlinkpathhead = fnamemodify(backlinkpath, ":h")

            if backlinkpathhead == "."
                let l:newbacklinkpath = a:newfilename
            elseif backlinkpathhead == "/"
                let l:newbacklinkpath = "/".a:newfilename
            else
                let l:newbacklinkpath = backlinkpathhead."/".a:newfilename
            endif

            let l:newbacklink = "[".newbacklinkpath.backlinkheader."]"
            silent execute "!sed -i 's+\\[".backlink[1:-2]."\\]+".newbacklink."+g' '".
                \ root.fpath."'"
        endif
    endfor

    " delete old file
    execute "w ".a:newfilename
    silent execute "!rm ".curfilename
    execute "bd"

    " open new file
    execute "e ".a:newfilename
    execute "redraw!"

    echo "(mdkasten) Renamed" curfilename "to" a:newfilename
endfunction

