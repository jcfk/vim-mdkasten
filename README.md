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

Write the global `g:mdkasten` in your vimrc:

    let g:mdkasten = [
        {
            "root": "/path/to/kasten",
            "prunes": ["/paths", "/to", "/ignore"],
            "priorities": ["/paths", "/to", "/search/first", "/"]
        }
    ]

Each element of this list is the metadata for one zettelkasten
instance. The *zettelkasten root directory* is the location of the
zettellkasten. Markdown files under this point and not in a pruned
directory are called *zettelkasten files*. See "search" for info on
priorities.

Inside any zettelkasten file `/path/to/kasten/file1.md`, you can
include **relative links**:

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

**List all zettelkasten files** via an fzf interface with `:MdkOpenFile`.

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

#### Search priorities

With a large directory tree, `find`ing all zettelkasten files can take
a while. To prioritize grepping through the immediate children of a
certain directory, add it to the `g:mdkasten` priorities list.

### Rename

**Rename the current file** with `:MdkRename newfilename.md`. This
changes all links pointing to the current file, kasten-wide.



