" FOPS - 'File Operations'
"
" A simple Vim plugin that provides a number of handy file operations.
"
" Author:       cwshugg
" Repository:   https://github.com/cwshugg/fops.vim

" Make sure we don't load this plugin more than once!
if exists('g:fops_initialized')
    finish
endif
let g:fops_initialized = 1

" File - A general-purpose command that spits out lots of information about a
" file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_complete
    \ File
    \ call fops#commands#file(<q-args>)


" File Path - Echoes out the current file's path.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_path_complete
    \ FilePath
    \ call fops#commands#file_path(<q-args>)

" File Type - Effectively a wrapper for the Linux `file` command. Displays
" information on the file's contents.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_type_complete
    \ FileType
    \ call fops#commands#file_type(<q-args>)

" File Size - Displays the file's size.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_size_complete
    \ FileSize
    \ call fops#commands#file_size(<q-args>)

" Edit - Modifies the current buffer to edit the specified file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_edit_complete
    \ FileEdit
    \ call fops#commands#file_edit(<q-args>)

" Find - Searches for a specified file or directory.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_find_complete
    \ FileFind
    \ call fops#commands#file_find(<q-args>)

" Delete - Deletes a file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_delete_complete
    \ FileDelete
    \ call fops#commands#file_delete(<q-args>)

" Copy - Saves a copy of the file in the current buffer.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_copy_complete
    \ FileCopy
    \ call fops#commands#file_copy(<q-args>)

" Move - Relocates the current file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_move_complete
    \ FileMove
    \ call fops#commands#file_move(<q-args>)

" Rename - Renames the current file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_rename_complete
    \ FileRename
    \ call fops#commands#file_rename(<q-args>)

" Yank - Writes the full path, or some other part of the file's path into a
" register. (The unnamed register by default.)
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_yank_complete
    \ FileYank
    \ call fops#commands#file_yank(<q-args>)

" Tree - Displays a tree of files from the source/current directory.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_tree_complete
    \ FileTree
    \ call fops#commands#file_tree(<q-args>)

