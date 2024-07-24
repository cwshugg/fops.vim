" This file implements file utility functions used by the front-facing plugin
" command functions.


" ======================= Messaging and Error Handling ======================= "
" Standard message printing for the plugin.
function! fops#utils#print(msg) abort
    echomsg fops#config#get('print_prefix') . a:msg
endfunction

" Displays a debug print message.
function! fops#utils#print_debug(msg) abort
    if fops#config#get('show_debug_prints')
        echohl WarningMsg
        echomsg fops#config#get('debug_print_prefix') . a:msg
        echohl None
    endif
endfunction

" Displays an error message.
function! fops#utils#print_error(msg) abort
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

" Used when an error is encountered and processing must stop.
function! fops#utils#panic(msg) abort
    throw fops#config#get('error_print_prefix') . a:msg
endfunction


" =========================== Shell/System Helpers =========================== "
function! fops#utils#run_shell_command(cmd) abort
    call fops#utils#print_debug('Executing shell command: "' . a:cmd . '"')
    return system(a:cmd)
endfunction


" ============================ String Operations ============================= "
" Compares two strings case-sensitively.
function! fops#utils#str_cmp(str1, str2) abort
    return a:str1 is# a:str2
endfunction

" Returns true if the string begins with the given prefix.
function! fops#utils#str_begins_with(str, prefix) abort
    let l:cmp_len = len(a:prefix)
    let l:cmp_str = strpart(a:str, 0, l:cmp_len)
    return fops#utils#str_cmp(l:cmp_str, a:prefix)
endfunction


" ============================= File Operations ============================== "
" Returns a string path to the file in the current buffer.
function! fops#utils#get_current_file()
    let l:out = expand("%:p")
    return l:out
endfunction

" Returns Vim's current working directory.
function! fops#utils#get_pwd()
    return getcwd()
endfunction

" Returns the dirname of the given path.
function! fops#utils#path_get_dirname(path) abort
    return fnamemodify(a:path, ':h')
endfunction

" Returns the basename of the given path.
function! fops#utils#path_get_basename(path) abort
    return fnamemodify(a:path, ':t')
endfunction

" Returns the extension of the given file path (the final portion of the full
" path that is preceded by a single dot).
function! fops#utils#path_get_extension(path) abort
    return fnamemodify(a:path, ':e')
endfunction

" Returns the entire file path, minus the extension.
function! fops#utils#path_remove_extension(path) abort
    return fnamemodify(a:path, ':r')
endfunction

" Returns true if the given path string points to a valid file.
function! fops#utils#path_is_file(path) abort
    return filereadable(a:path)
endfunction

" Returns true if the given path string points to a valid directory
function! fops#utils#path_is_dir(path) abort
    return isdirectory(a:path)
endfunction

" Retrieves information about the given file.
function! fops#utils#file_get_info(src_path)
    let l:cmd = 'file ' . a:src_path
    return trim(fops#utils#run_shell_command(l:cmd))
endfunction

" Retrieves the size of the given file. Returns the size, in bytes.
function! fops#utils#file_get_size(src_path)
    return getfsize(a:src_path)
endfunction

" Returns a formatted file size string.
function! fops#utils#format_file_size(bytes)
    let l:suffixes = ['B', 'KB', 'MB', 'GB', 'TB']
    let l:suffixes_len = len(l:suffixes)
    let l:count = 0
    let l:bytes = a:bytes

    " continually divide by 1024 to determine which size suffix to select
    while l:bytes >= 1024 && l:count < l:suffixes_len
        let l:bytes = l:bytes / 1024
        let l:count += 1
    endwhile
    
    " build and return a formatted string with the resulting divided size and
    " the chosen suffix
    return printf('%.2f %s', l:bytes, l:suffixes[l:count])
endfunction

" Searches the given directory for a file with the given query string. The
" entry is recursively searched for, and a list of matches is returned.
function! fops#utils#file_find(dir, query)
    let l:matches = split(globpath(a:dir, '**/' . a:query), "\n")
    return l:matches
endfunction

" Copies the file to the given destination path.
function! fops#utils#file_copy(src_path, dst_path)
    " build a `cp` command (including `-r` for directories)
    let l:cmd = 'cp '
    if fops#utils#path_is_dir(a:src_path)
        let l:cmd .= '-r '
    endif
    let l:cmd .= shellescape(a:src_path) . ' '
    let l:cmd .= shellescape(a:dst_path)

    call fops#utils#run_shell_command(l:cmd)
endfunction

" Moves the file to the given destination path.
function! fops#utils#file_move(src_path, dst_path)
    " build a `mv` command
    let l:cmd = 'mv '
    let l:cmd .= shellescape(a:src_path) . ' '
    let l:cmd .= shellescape(a:dst_path)

    call fops#utils#run_shell_command(l:cmd)
endfunction

" Renames the file to have the given new name. (The file's location remains
" the same; only its name is changed.)
"
" Returns the new path of the renamed file.
function! fops#utils#file_rename(src_path, name)
    " build a full file path for the renamed file
    let l:dst_path = fops#utils#path_get_dirname(a:src_path)
    let l:dst_path .= '/' . fops#utils#path_get_basename(a:name)

    " invoke the move function
    call fops#utils#file_move(a:src_path, l:dst_path)
    return l:dst_path
endfunction

