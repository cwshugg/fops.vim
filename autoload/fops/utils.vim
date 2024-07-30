" This file implements file utility functions used by the front-facing plugin
" command functions.


" ======================= Messaging and Error Handling ======================= "
" Standard message printing for the plugin.
function! fops#utils#print(msg) abort
    echomsg fops#config#get('print_prefix') . a:msg
endfunction

" Prints a message that is not committed to the message history and is printed
" as-is, with no newline at the end.
function! fops#utils#print_raw(msg) abort
    echon fops#config#get('print_prefix') . a:msg
    redraw
endfunction

" Clears the current output line.
function! fops#utils#print_raw_clear() abort
    echon "\r\033[K"
    redraw
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

" Compares two strings case-insensitively.
function! fops#utils#str_cmp_case_insensitive(str1, str2) abort
    return a:str1 is? a:str2
endfunction

" Returns true if the string begins with the given prefix.
function! fops#utils#str_begins_with(str, prefix) abort
    let l:cmp_len = len(a:prefix)
    let l:cmp_str = strpart(a:str, 0, l:cmp_len)
    return fops#utils#str_cmp(l:cmp_str, a:prefix)
endfunction

" Returns true if the string begins with the given prefix.
function! fops#utils#str_begins_with_case_insensitive(str, prefix) abort
    let l:cmp_len = len(a:prefix)
    let l:cmp_str = strpart(a:str, 0, l:cmp_len)
    return fops#utils#str_cmp_case_insensitive(l:cmp_str, a:prefix)
endfunction


" ================================ User Input ================================ "
" Reads input from the user with the provided prompt and returns it.
function! fops#utils#input_str(msg) abort
    return input(a:msg)
endfunction

" Propmts the user for a yes/no response. Returns `true` if yes was selected,
" and `false` if no was selected.
function! fops#utils#input_yesno(msg) abort
    let l:yes_values = ['y', 'yes', '1']
    let l:no_values = ['n', 'no', '0']
    
    " iterate until a value decision has been made
    while v:true
        let l:choice = trim(fops#utils#input_str(a:msg))

        " did the user select yes?
        for l:yv in l:yes_values
            if fops#utils#str_cmp_case_insensitive(l:choice, l:yv)
                return v:true
            endif
        endfor

        " did the user select no?
        for l:nv in l:no_values
            if fops#utils#str_cmp_case_insensitive(l:choice, l:nv)
                return v:false
            endif
        endfor
    endwhile
    return v:null
endfunction

" Reads user input and attempts to convert it to a number.
function! fops#utils#input_number(msg) abort
    return str2nr(fops#utils#input_str(a:msg))
endfunction

" Reads input from the user and attempts to convert it to an integer. The
" `values` parameter should be a list of number values that are accepted
" inputs. This function will repeatedly prompt until a value in the list is
" specified. If the list is empty, all values are accepted.
function! fops#utils#input_number_values(msg, values) abort
    let l:values_len = len(a:values)

    let l:num = 0
    while v:true
        " read input and attempt to convert to an integer
        let l:num = fops#utils#input_number(a:msg)

        " if a list of values was not provided, we're done; accept the first
        " value the user inputs
        if l:values_len == 0
            break
        endif

        " otherwise, make sure the interpreted number is in the list
        if index(a:values, l:num) != -1
            break
        endif
    endwhile

    return l:num
endfunction


" ============================== Vim Registers =============================== "
" Returns the register character if the given register is a valid register
" name. Returns v:null on a mismatch.
function! fops#utils#reg_lookup(name) abort
    let l:valid_registers = 'abcdefghijklmnopqrstuvwxyz' .
                          \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' .
                          \ '0123456789' .
                          \ '"-:.%#=*+~_/'
    let l:idx = match(l:valid_registers, a:name[0])
    if l:idx < 0
        return v:null
    endif
    return l:valid_registers[l:idx]
endfunction

" Writes to a register.
function! fops#utils#reg_write(name, value) abort
    let l:reg = fops#utils#reg_lookup(a:name)
    if l:reg is v:null
        call fops#utils#panic('Invalid register name: "' . a:name . '"')
    endif
    
    call setreg(l:reg, a:value)
endfunction

" Reads from a register and returns its value.
function! fops#utils#reg_read(name, value) abort
    let l:reg = fops#utils#reg_lookup(a:name)
    if l:reg is v:null
        call fops#utils#panic('Invalid register name: "' . a:name . '"')
    endif

    return getreg(l:reg)
endfunction


" ============================= File Operations ============================== "
" Returns a string path to the file in the current buffer.
function! fops#utils#get_current_file() abort
    let l:out = expand("%:p")
    return l:out
endfunction

" Returns Vim's current working directory.
function! fops#utils#get_pwd() abort
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

" Returns the absolute path of the given path string.
function! fops#utils#path_get_absolute(path) abort
    return fnamemodify(a:path, ':p')
endfunction

" Returns the entire file path, minus the extension.
function! fops#utils#path_remove_extension(path) abort
    return fnamemodify(a:path, ':r')
endfunction

" Modifies the given path and produces a copy with the new basename.
function! fops#utils#path_set_basename(path, name) abort
    let l:result = fops#utils#path_get_dirname(a:path)
    let l:result .= '/' . fops#utils#path_get_basename(a:name)
    return l:result
endfunction

" Returns true if the given path string points to a valid file.
function! fops#utils#path_is_file(path) abort
    return filereadable(a:path)
endfunction

" Returns true if the given path string points to a valid directory
function! fops#utils#path_is_dir(path) abort
    return isdirectory(a:path)
endfunction

" Returns the combined `path` and `name`, while avoiding double slashes in the
" string.
function! fops#utils#path_append(path, name) abort
    " remove the trailing slash, if it exists
    let l:result = fnamemodify(a:path, ':p:h')
    let l:result = l:result . '/' . a:name
    return l:result
endfunction

" Retrieves information about the given file.
function! fops#utils#file_get_info(src_path) abort
    let l:cmd = 'file ' . a:src_path
    return trim(fops#utils#run_shell_command(l:cmd))
endfunction

" Retrieves the size of the given file. Returns the size, in bytes.
function! fops#utils#file_get_size(src_path) abort
    return getfsize(a:src_path)
endfunction

" Returns a formatted file size string.
function! fops#utils#format_file_size(bytes) abort
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
function! fops#utils#file_find(dir, query) abort
    let l:matches = globpath(a:dir, '**/' . a:query, v:false, v:true)
    return l:matches
endfunction

" Copies the file to the given destination path.
function! fops#utils#file_copy(src_path, dst_path) abort
    " build a `cp` command (including `-r` for directories)
    let l:cmd = 'cp '
    if fops#utils#path_is_dir(a:src_path)
        let l:cmd .= '-r '
    endif
    let l:cmd .= shellescape(a:src_path) . ' '
    let l:cmd .= shellescape(a:dst_path)

    call fops#utils#run_shell_command(l:cmd)
endfunction

" Deletes the given file or directory. Directories are deleted recursively,
" including everything within.
function! fops#utils#file_delete(src_path) abort
    " make sure the file exists
    let l:is_file = fops#utils#path_is_file(a:src_path)
    let l:is_dir = fops#utils#path_is_dir(a:src_path)
    if !l:is_file && !l:is_dir
        let l:errmsg = 'The file "' . a:src_path .
                     \ '" does not exist and thus cannot be deleted.'
        call fops#utils#panic(l:errmsg)
    endif

    " determine what deletion flags to use
    let l:flags = ''
    if fops#utils#path_is_dir(a:src_path)
        let l:flags = 'rf'
    endif
    
    if delete(a:src_path, l:flags) != 0
        call fops#utils#panic('Failed to delete file "' . a:src_path . '".')
    endif
endfunction

" Moves the file to the given destination path.
function! fops#utils#file_move(src_path, dst_path) abort
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
function! fops#utils#file_rename(src_path, name) abort
    " build a full file path for the renamed file
    let l:dst_path = fops#utils#path_get_dirname(a:src_path)
    let l:dst_path .= '/' . fops#utils#path_get_basename(a:name)

    " invoke the move function
    call fops#utils#file_move(a:src_path, l:dst_path)
    return l:dst_path
endfunction

" Returns a list of children under the given directory.
function! fops#utils#dir_get_entries(path) abort
    let l:files = globpath(a:path, '/*', v:false, v:true)
    let l:files_len = len(l:files)
    
    " remove double slashes from the resulting file paths
    for l:idx in range(l:files_len)
        let l:files[l:idx] = substitute(l:files[l:idx], '//', '/', 'g')
    endfor
    return l:files
endfunction

