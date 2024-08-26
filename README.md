# Vim FOPS

This Vim plugin provides several commands for performing file-related
operations. Copy, move, rename, delete, and find files directly from the Vim
command window. Plus, keep your current buffer updated. Did you just rename the
file you're currently editing?  No worries; FOPS can update your buffer to edit
the renamed version. Want to glob-search for a file, and select one of the
matches to edit? FOPS has you covered there, too.

## Demo

Use FOPS to retrieve file information, make copies, move files, delete files,
and rename files. Notice how by specifying the `-e`/`--edit` option in the
below GIF, the current Vim window automatically is updated to edit the new
file:

![](https://shugg.dev/images/fops.vim/fops_demo_commands.gif)

You can also use the `FileYank` command to write various components of file
paths into the Vim registers:

![](https://shugg.dev/images/fops.vim/fops_demo_yank.gif)

Need to find a file by name? Use glob-searching in `FileFind` to list all files
that match your search. Include `-e`/`--edit` to select one of the results to
update your current Vim buffer:

![](https://shugg.dev/images/fops.vim/fops_demo_find.gif)

Want to view the entire file tree (and, you guessed it, select a file to edit
using `-e`/`--edit`)? Use `FileTree`:

![](https://shugg.dev/images/fops.vim/fops_demo_tree.gif)

## Installation

FOPS depends on [argonaut.vim](https://github.com/cwshugg/argonaut.vim),
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

### `FileEdit`

Updates the current buffer to edit a new file. Just like `:edit`, but it
additionally pushes the old file to the current buffer's file stack. (See the
`FilePop` command for why you might find this useful.)

```vim
:FileEdit
:FileEdit ~/.bashrc
```

### `FileStack`

Displays the contents of the current buffer's file stack. If you used other
FOPS commands while in this buffer to edit new files (such as `FileEdit`,
`FileFind -e`, or `FileTree -e`), then FOPS has internally pushed old files to
a stack, specified to this buffer. This command allows you to see whats in the
stack.

```vim
:FileStack
```

### `FilePop`

Pops the top entry off of the current buffer's file stack, and modifies the
buffer to edit the popped file.

```vim
:FilePop
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

## File Stack API

As mentioned above, FOPS keeps track of an internal file stack for each unique
buffer in Vim. You can interact with the file stack with a few of FOPS'
commands (push to the stack with `FileEdit`, pop with `FilePop`, view the stack
with `FileStack`).

You may want to have *your* Vim plugins/scripts interact with the file stack
programmatically. The functions defined in `autoload/fops/fstack.vim` provide
an interface for you to do so. Here's an example of using these functions to
push a new entry onto the file stack for the current buffer:

```vim
function! s:your_custom_function(...)
    " retrieve the buffer ID, so FOPS knows what buffer's file stack to modify
    let l:buffer_id = fops#fstack#get_buffer_id()

    " use the buffer ID to generate a new entry to the buffer's file stack,
    " that represents the file that buffer is currently editing
    let l:entry = fops#fstack#get_buffer_entry(l:buffer_id)

    " (or, create one manually)
    let l:entry = fops#fstack#entry#new()
    call fops#fstack#entry#set_path(l:entry, '/your/custom/file/path')
    call fops#fstack#entry#set_cursor_line(l:entry, 23)
    call fops#fstack#entry#set_cursor_col(l:entry, 67)

    " push the new entry to the buffer's file stack
    call fops#fstack#push(l:buffer_id, l:entry)
endfunction
```

On the flipside, here's an example showing how to pop from a buffer's file
stack, and update the buffer to edit the popped file.

```vim
function! s:your_custom_function2(...)
    " retrieve the buffer ID, so FOPS knows what buffer's file stack to modify
    let l:buffer_id = fops#fstack#get_buffer_id()
    
    " pop and store the popped entry (make sure to check for an empty stack)
    let l:entry = fops#fstack#pop(l:buffer_id)
    if l:entry is v:null
        echo 'File stack is empty for buffer #' . l:buffer_id . '!'
        return
    endif
    
    " call the handy helper function that updates the buffer (or, you can
    " implement this bit by yourself)
    call fops#fstack#apply(l:buffer_id, l:entry)
endfunction
```

