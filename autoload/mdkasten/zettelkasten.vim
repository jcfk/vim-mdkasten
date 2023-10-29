" Utils

"" Kasten-wide

function s:GetKastenMeta()
    let l:fpath = expand("%:p")
    for kasten in g:mdkasten
        if fpath =~ '\v^'.kasten["root"].'.*'
            return kasten
        endif
    endfor
endfunction

function s:MakeFindOptions() " listing exactly the zettelkasten files
    " root
    let l:kasten = s:GetKastenMeta()
    let [ l:root, l:prunes ] = [ kasten["root"], kasten["prunes"] ]
    let l:ret = root

    " ignore
    let l:ignorelist = []
    for prune in prunes
        call add(ignorelist, "-path \"".root.prune."\"")
    endfor
    let l:ret .= " -type d \\( ".join(ignorelist, " -o ")." \\) -prune"
    " -type d is needed here because we may have top-level files whose names
    " match one of the prune patterns. We are skipping just the directories.

    " iname
    let l:ret .= " -o -iname '*.md'"

    " echom ret
    return ret " a print action must be appended at this point
endfunction

function s:MakeFindGrepPipelines(grepopts)
    " root
    let l:kasten = s:GetKastenMeta()
    let [ l:root, l:priorities ] = [ kasten["root"], kasten["priorities"] ]
    let l:ret = "{"

    " priorities
    let l:findinstances = []
    for priority in priorities
        call add(findinstances, "find ".simplify(root.priority).
            \ " -maxdepth 1 -iname '*.md' -print0".
            \ " | xargs -0 ".a:grepopts)
    endfor
    let l:ret .= " ".join(findinstances, " && ")

    " general
    let l:ret .= " && find ".s:MakeFindOptions()." -print0".
        \ " | xargs -0 ".a:grepopts." ; }"

    " cutting
    let l:ret .= " | sed -u 's+".root."++g' | stdbuf -oL awk '!seen[$0]++'"

    return ret
endfunction

"" Local

function s:IsValidFilename(fname)
    if a:fname !~ '\v^\S*\.md'
        return 0
    endif

    if filereadable(a:fname)
        return 0
    endif

    return 1
endfunction

function s:ParseLink(link)
    let l:i = 0
    while i < strlen(a:link)
        if a:link[i] == '#'
            break
        endif
        let l:i += 1
    endwhile

    " [link fpath, link header]
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

function s:FileToTitle(link)
    let l:ret = substitute(split(a:link[:-4], "/")[-1], "-", " ", "g")
    return toupper(l:ret[0]) . l:ret[1:]
endfunction

function s:InsertLink(fpath)
    silent execute "normal a[" . a:fpath . "]"
endfunction

"" Handlers

function s:OpenFile(fpath)
    silent execute "e" s:GetKastenMeta()["root"].a:fpath
endfunction

function s:OpenBacklink(curfname, fpath)
    call s:OpenSearch("\\[\\(.*\\/\\)*".a:curfname."\\(#\\|\\]\\)", a:fpath)
endfunction

function s:OpenSearch(query, fpath)
    silent execute "e" s:GetKastenMeta()["root"].a:fpath "| /".a:query
endfunction

function s:OpenSearchRg(line)
    let l:components = split(a:line, ":")
    let l:fpath = components[0]
    let l:linenum = components[1]
    silent execute "e" s:GetKastenMeta()["root"].fpath "| :".linenum
endfunction

" Actions

function mdkasten#zettelkasten#OpenFile()
    let l:source = "find ".s:MakeFindOptions()." -printf '/%P\n'"
	call fzf#run(fzf#wrap({
        \ 'options': ["--prompt", "MdkOpenFile> "],
        \ 'source': source, 
        \ 'sink': function("s:OpenFile")
        \ }))
endfunction

function mdkasten#zettelkasten#InsertLink()
    let l:source = "find ".s:MakeFindOptions()." -printf '/%P\n'"
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
    let [l:fpath, l:header] = s:GetCursorLink()
    if len(fpath) == 0
        echo "(mdkasten) No link found under cursor."
        return
    endif

    " kasten-absolute paths
    if fpath[0] == "/"
        let l:fpath = s:GetKastenMeta()["root"].fpath
    endif

	" symlinks
	let l:readlink = system("readlink ".fpath)
	if len(readlink)
        let l:fpath = readlink
	endif

    let l:ext = fnamemodify(fpath, ":e")
    if index(["md", "txt"], ext) >= 0
        if filereadable(fpath)
            if header == ""
                silent execute "e" fpath
            else
                silent execute "e" fpath "| /^".header
            endif
        else
            execute "e" fpath
            execute "normal i#" s:FileToTitle(fpath)."\n\n"
            echo "(mdkasten) New file created."
        endif
    else
        execute "!gloom ".fpath
    endif
endfunction

function mdkasten#zettelkasten#OpenBacklink()
    let l:fname = expand('%:t')
    let l:source = s:MakeFindGrepPipelines("grep -sl -E '\\[/?(.+/)*".fname."(#+ .+)?\\]'")
    " echom source
	call fzf#run(fzf#wrap({
        \ 'options': ["--prompt", "MdkOpenBacklink> "],
        \ 'source': source, 
        \ 'sink': function("s:OpenBacklink", [fname])
        \ }))
endfunction

function mdkasten#zettelkasten#Search(query)
    if len(a:query)
        let l:source = s:MakeFindGrepPipelines("grep -sli -E '".a:query."'")
        call fzf#run(fzf#wrap({
            \ 'options': ["--prompt", "MdkSearch> "],
            \ 'source': source, 
            \ 'sink': function("s:OpenSearch", [a:query])
            \ }))
    else
        let l:source = "find ".s:MakeFindOptions()." -print0".
            \ " | xargs -0 rg --line-number --color=always --smart-case ''".
            \ " | sed 's+".s:GetKastenMeta()["root"]."++g'"
        call fzf#run(fzf#wrap({
            \ "options": ["--exact", "--color", "hl:9:bold", "--ansi",
                \ "--prompt", "MdkSearch> ", "--delimiter", ":",
                \ "--nth", "3.."],
            \ "source": source,
            \ "sink": function("s:OpenSearchRg")
            \ }))
    endif
endfunction

function mdkasten#zettelkasten#Rename(newfname)
    let l:root = s:GetKastenMeta()["root"]
    let l:curfname = expand('%:t')
    let l:curfpath = expand('%:p')[len(root):]

    " check validity of new title
    if a:newfname !~ '\v^\S*\.md'
        echo "(mdkasten) Invalid filename."
        return
    endif
    if filereadable(a:newfname)
        echo "(mdkasten) File already exists."
        return
    endif

    " change all kasten links
    let l:findoutput = systemlist("find ".s:MakeFindOptions()." -print0".
        \ " | xargs -0 grep -so -E '\\[/?(.+/)*".curfname."(#+ .+)?\\]'".
        \ " | cut -c ".(len(s:GetKastenMeta()["root"])+1)."-")
    for line in findoutput
        let [l:fpath, l:backlink] = split(line, ":")
        let [l:backlinkpath, l:backlinkheader] = s:ParseLink(backlink[1:-2])

        if backlinkpath[0] == "/"
            let l:backlinkpathabs = backlinkpath
        else
            let l:backlinkpathabs = "/".systemlist('realpath --relative-base '.root.
                \ ' "'.root.fnamemodify(fpath, ":h").'/'.backlinkpath.'"')[0]
        endif

        if backlinkpathabs == curfpath
            let l:backlinkpathhead = fnamemodify(backlinkpath, ":h")

            if backlinkpathhead == "."
                let l:newbacklinkpath = a:newfname
            elseif backlinkpathhead == "/"
                let l:newbacklinkpath = "/".a:newfname
            else
                let l:newbacklinkpath = backlinkpathhead."/".a:newfname
            endif

            let l:newbacklink = "[".newbacklinkpath.backlinkheader."]"
            silent execute "!sed -i 's+\\[".backlink[1:-2]."\\]+".
                \ newbacklink."+g' '".root.fpath."'"
        endif
    endfor

    " delete old file
    execute "w ".a:newfname
    silent execute "!rm ".curfname
    execute "bd"

    " open new file
    execute "e ".a:newfname
    execute "redraw!"

    echo "(mdkasten) Renamed" curfname "to" a:newfname
endfunction

