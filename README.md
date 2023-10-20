# vim-mdkasten - simple markdown zettelkasten for vim

Connect markdown files residing in an ordinary directory tree via link
and backlink navigation.

More features:

* File search (`rg` + `fzf`)
* File renaming kasten-wide
* Detailed links (to specific markdown headers)

Requirements:

* `fzf.vim` (as described [here](https://github.com/junegunn/fzf.vim))
* local `rg` installation

## Quick intro

Create a dir named `.mdkasten` in the directory `/path/to/kasten`
containing the markdown files. Directory `/path/to/kasten` becomes the
*zettelkasten root directory*. All markdown files beneath this point
become *zettelkasten files*.

Inside any markdown file `/path/to/kasten/file1.md`, you can include
**relative links**:

    # Contents of `/path/to/kasten/file1.md`

    Here [file2.md] is a relative link to `/path/to/kasten/file2.md`.

    Here [dir1/file1.md] is a relative link to `/path/to/kasten/dir1/file1.md`.

**Follow the link** by placing the cursor over it and calling
`MdkFollowLink`.

**Open a backlink** of the current file via an fzf interface with
`:MdkOpenBacklink`. This lists all zettelkasten files which link to
the current file.

## More features

### Zettelkasten files

**Open a zettelkasten file** via an fzf interface with `:MdkOpenFile`.

### Links

Use **absolute links** (beginning with a `/`) for ease of navigation
from sub-directories:

    # Contents of `/path/to/kasten/dir1/file1.md`

    Here [/file1.md] is an absolute link to `/path/to/kasten/file1.md`.

    Here [/dir2/file1.md] is an absolute link to `/path/to/kasten/dir2/file1.md`.

Include **headers in links** to link to a particular header in the
desired file:

    # Contents of `/path/to/kasten/file1.md`

    Here [file2.md## Header1] is a relative link to `/path/to/kasten/file2.md`, 
    and will automatically navigate to the first occurance of the line
    `## Header1`.

### Search

**Search the zettelkasten** with `:MdkSearch`. If an argument `A` is
provided, an fzf interface is created containing the output of `grep
-sli -E "A"` over all zettelkasten files.

If an argument is not provided, an fzf dialog is given containing the
line-by-line contents of all zettelkasten files, allowing interactive
search via fzf (like `fzf.vim`'s `:Rg`).

### Rename

**Rename the current file** with `:MdkRename newfilename.md`. This
changes all links pointing to the current file, kasten-wide.



