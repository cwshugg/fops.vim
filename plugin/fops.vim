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

" Creates a safe command alias for commands that begin with ':'.
"
" * 'alias' represents the string that will become the new alias.
" * 'source' represents the existing command you wish to create an alias for.
"
" Credit to this StackOverflow post:
" https://stackoverflow.com/questions/3878692/how-to-create-an-alias-for-a-command-in-vim
function! s:fops_create_command_alias(source, alias)
      exec 'cnoreabbrev <expr> '.a:alias
         \ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:alias.'")'
         \ .'? ("'.a:source.'") : ("'.a:alias.'"))'
endfunction

" File Path - Echoes out the current file's path.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_path_complete
    \ FopPath
    \ call fops#commands#file_path(<q-args>)
call s:fops_create_command_alias('FopPath', 'FilePath')
call s:fops_create_command_alias('FopPath', 'FPath')

" File Info - Effectively a wrapper for the Linux `file` command. Displays
" information on the file and its contents.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_info_complete
    \ FopInfo
    \ call fops#commands#file_info(<q-args>)
call s:fops_create_command_alias('FopInfo', 'FileInfo')
call s:fops_create_command_alias('FopInfo', 'FInfo')

" File Size - Displays the file's size.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_size_complete
    \ FopSize
    \ call fops#commands#file_size(<q-args>)
call s:fops_create_command_alias('FopSize', 'FileSize')
call s:fops_create_command_alias('FopSize', 'FSize')

" Find - Searches for a specified file or directory.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_find_complete
    \ FopFind
    \ call fops#commands#file_find(<q-args>)
call s:fops_create_command_alias('FopFind', 'FileFind')
call s:fops_create_command_alias('FopFind', 'FFind')

" Delete - Deletes a file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_delete_complete
    \ FopDelete
    \ call fops#commands#file_delete(<q-args>)
call s:fops_create_command_alias('FopDelete', 'FileDelete')
call s:fops_create_command_alias('FopDelete', 'FDelete')


" Copy - Saves a copy of the file in the current buffer.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_copy_complete
    \ FopCopy
    \ call fops#commands#file_copy(<q-args>)
call s:fops_create_command_alias('FopCopy', 'FileCopy')
call s:fops_create_command_alias('FopCopy', 'FCopy')

" Move - Relocates the current file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_move_complete
    \ FopMove
    \ call fops#commands#file_move(<q-args>)
call s:fops_create_command_alias('FopMove', 'FileMove')
call s:fops_create_command_alias('FopMove', 'FMove')

" Rename - Renames the current file.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_rename_complete
    \ FopRename
    \ call fops#commands#file_rename(<q-args>)
call s:fops_create_command_alias('FopRename', 'FileRename')
call s:fops_create_command_alias('FopRename', 'FRename')

" RenameExtension - Renames the current file by modifying its extension.
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_rename_extension_complete
    \ FopRenameExtension
    \ call fops#commands#file_rename_extension(<q-args>)
call s:fops_create_command_alias('FopRenameExtension', 'FileRenameExtension')
call s:fops_create_command_alias('FopRenameExtension', 'FRenameExtension')

" Yank - Writes the full path, or some other part of the file's path into a
" register. (The unnamed register by default.)
command!
    \ -nargs=*
    \ -complete=customlist,fops#commands#file_yank_complete
    \ FopYank
    \ call fops#commands#file_yank(<q-args>)
call s:fops_create_command_alias('FopYank', 'FileYank')
call s:fops_create_command_alias('FopYank', 'FYank')

