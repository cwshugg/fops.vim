# Vim FOPS

This Vim plugin provides several commands for performing file-related
operations. Copy, move, rename, delete, and find files directly from the Vim
command window. Plus, keep your current buffer updated. Did you just rename the
file you're currently editing?  No worries; FOPS can update your buffer to edit
the renamed version. Want to glob-search for a file, and select one of the
matches to edit? FOPS has you covered there, too.

## Demo

Here's a quick demonstration of some of FOPS' functionality:

TODO - GIF!

## Installation

FOPS is depending on [argonaut.vim](https://github.com/cwshugg/argonaut.vim),
my Vim argument parsing plugin, to provide some handy knobs and switches for
this plugin's various commands. Install both of them with your favorite plugin
manager:

```vim
" Vundle:
Plugin 'cwshugg/argonaut.vim'
Plugin 'cwshugg/fops.vim'

" vim-plug
Plug 'cwshugg/argonaut.vim'
Plug 'cwshugg/fops.vim'

" minpac
call minpac#add('cwshugg/argonaut.vim')
call minpac#add('cwshugg/fops.vim')
```

Or, clone them manually:

```bash
$ git clone https://github.com/cwshugg/argonaut.vim ~/.vim/bundle/argonaut.vim
$ git clone https://github.com/cwshugg/fops.vim ~/.vim/bundle/fops.vim
```

## Commands

The following commands are provided by this plugin. (For each command you can
always run with `-h` or `--help` to see a menu of all possible command-line
options!)

### `File`

Displays general information about your buffer's current file, or the full path
of *any* file you specify:

```vim
:File
:File ~/.bashrc
```

### `FilePath`

Displays the full path of your buffer's current file, or the full path of *any*
file you specify:

```vim
:FilePath
:FilePath ~/.bashrc
```

### `FileType`

Effectively a wrapper for the Linux `file` command; this displays the type of
contents found within the current (or specified) file:

```vim
:FileType
:FileType ~/.bashrc
```

### `FileSize`

Displays the total number of bytes in a file:

```vim
:FileSize
:FileSize ~/.bashrc
```

### `FileDelete`

Deletes the current file or some other file from the filesystem.

```vim
:FileDelete
:FileDelete ~/notes/file.txt

" Want to wipe your current buffer after deleting its file?
:FileDelete -e
```

### `FileCopy`

Copies the current file (or some other file) to a new location.

```vim
:FileCopy /path/to/destination.txt
:FileCopy /path/to/source.txt /path/to/destination.txt

" Want to edit the new copy in the current buffer?
:FileCopy /path/to/destination.txt -e
```

### `FileMove`

Moves the current file (or some other file) to a new location.

```vim
:FileMove /path/to/destination.txt
:FileMove /path/to/source.txt /path/to/destination.txt

" Want to edit the relocated file in the current buffer?
:FileMove /path/to/destination.txt -e
```

### `FileRename`

Renames the current file (or some other file). Only the file name is modified;
its location in its current parent directory is unchanged.

```vim
:FileRename newname.txt
:FileRename /path/to/old.txt newname.txt

" Want to edit the renamed file in the current buffer?
:FileRename newname.txt -e

" Want to rename the name, but keep the same extension?
:FileRename -rn newname

" Want to rename the extension, but keep the same name?
:FileRename -re md
```

### `FileYank`

Copies aspects of a file's path into a register. (By default, the unnamed (`"`)
register is used, but any register can be written to by specifying the
`--register` argument.)

```vim
" To yank the full file path of the current (or some other) file:
:FileYank
:FileYank /path/to/file.txt

" To yank into register `@a`:
:FileYank -r a
:FileYank /path/to/file.txt -r a

" Want to yank only the basename?
:FileYank -yb

" Want to yank only the dirname?
:FileYank -yd

" Want to yank only the extension?
:FileYank -ye
```

### `FileFind`

Searches for files matching a specific glob-string and displays the results. To
select one of the matching files to edit in your current buffer, use `-e`.

```vim
" To search from the directory your current buffer's file is in:
:FileFind *.txt

" To search from some other directory:
:FileFind ${HOME}/notes *.txt

" To update your buffer to edit one of the matching files:
:FileFind ${HOME}/notes *.txt -e
```

### `FileTree`

Displays a tree of all files underneath the current (or some other) file's
parent directory. To select one of the displayed files to edit in your current
buffer, use `-e`.

```vim
:FileTree
:FileTree ${HOME}/notes

" To update your buffer to edit one of the displayed files:
:FileTree ${HOME}/notes -e
```

## Documentation

Want to get into the nitty gritty details of the plugin? Open up the Vim help
page:

```vim
:h fops
```

