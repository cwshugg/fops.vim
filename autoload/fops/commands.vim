" This file implements the front-facing functions for all fops.vim commands.


" ============================= Argument Parsing ============================= "
" The `-h`/`--help` argument is used in all of the commands in this plugin to
" display a help menu.
let s:arg_help = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_help, argonaut#argid#new('-', 'h'))
call argonaut#arg#add_argid(s:arg_help, argonaut#argid#new('--', 'help'))
call argonaut#arg#set_description(s:arg_help,
    \ 'Shows this help menu.'
\ )

" The `-e`/`--edit` argument is used by several of the commands in this
" plugin. This allows the user to tell the command to re-open the
" renamed/remodified file in the current buffer.
let s:arg_edit = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_edit, argonaut#argid#new('-', 'e'))
call argonaut#arg#add_argid(s:arg_edit, argonaut#argid#new('--', 'edit'))
call argonaut#arg#add_argid(s:arg_edit, argonaut#argid#new('-', 'u'))
call argonaut#arg#add_argid(s:arg_edit, argonaut#argid#new('--', 'update-buffer'))
call argonaut#arg#set_description(s:arg_edit,
    \ 'Updates the current buffer to edit the relocated/renamed/modified file.'
\ )


" ================================= Helpers ================================== "
" Prints a verbose message. The print only occurs if verbose messages are
" enabled in the plugin's config.
function! s:print_verbose(msg) abort
    if fops#config#get('show_verbose_prints')
        call fops#utils#print(a:msg)
    endif
endfunction

" Helper function that takes in an argparser object and shows the help menu if
" the `--help` argument (defined above) is specified. Returns true if the help
" menu was shown.
function! s:maybe_show_help_menu(parser) abort
    " if `--help` was not provided, quit early
    if !argonaut#argparser#has_arg(a:parser, '-h')
        return v:false
    endif
    
    " show the argonaut built-in help menu
    call argonaut#argparser#show_help(a:parser)
    return v:true
endfunction

" Updates the current buffer to modify the file at the given path.
function! s:retarget_current_buffer(path) abort
    " make sure the given file path is a valid file or directory
    if !fops#utils#path_is_file(a:path) && !fops#utils#path_is_dir(a:path)
        let l:errmsg .= 'The provided path (' . a:path .
                      \ ') is not a valid file or directory.'
        call fops#utils#panic(l:errmsg)
    endif

    " open the new file in the current buffer
    :silent execute 'edit ' . a:path
endfunction

" Checks the given parser for the presence of the `--edit` argument. If it's
" present, the current buffer is updated to edit the given file path.
"
" Returns true if the buffer was updated.
function! s:maybe_retarget_current_buffer(parser, path) abort
    " if `--edit` was not provided, quit early
    if !argonaut#argparser#has_arg(a:parser, '-e')
        return v:false
    endif

    " if the given file is null, or an empty string, we'll assume the caller
    " wants to edit a new, empty buffer
    if a:path is v:null || fops#utils#str_cmp(a:path, '')
        execute 'enew'
        return v:true
    endif
    
    call s:retarget_current_buffer(a:path)
    return v:true
endfunction

" Helper function that returns target files based on the expected number
" passed in. Typically this value is 1 or 2, because most of this plugin's
" commands accept one or two file paths as input.
"
" If one less than the expected number of file paths is provided, the first
" file path used will be the source file pointed at by the current buffer.
"
" The `check_list` should be a list of true/false values, indicating which of
" the arguments should be checked for file/directory existence. Each entry
" corresponds to the index in the final list of path strings.
function! s:get_inputs(parser, expected_count, check_list) abort
    " sanity check: make sure the check list's length matches the expected
    " number of file input paths
    call fops#utils#sanity(len(a:check_list) == a:expected_count)

    " retrieve the 'extra'/'unnamed' arguments from the parser
    let l:args = argonaut#argparser#get_extra_args(a:parser)
    let l:args_len = len(l:args)

    " if the number of arguments provided is too many, panic
    if l:args_len > a:expected_count
        let l:errmsg = 'Too many arguments were provided. '
        if a:expected_count > 1
            let l:errmsg .= 'You must provide at least ' . (a:expected_count - 1) . '.'
        else
            let l:errmsg .= 'You must provided none, or at most 1.'
        endif
        call fops#utils#panic(l:errmsg)
    endif

    " if the number of arguments provided is too little, panic
    if l:args_len < a:expected_count - 1
        let l:errmsg = 'Not enough arguments were provided. '
        if a:expected_count > 1
            let l:errmsg .= 'You must provide at least ' . (a:expected_count - 1) . '.'
        else
            let l:errmsg .= 'You must provided none, or at most 1.'
        endif
        call fops#utils#panic(l:errmsg)
    endif

    let l:paths = []
    let l:check_list_idx = 0
    let l:paths_remaining = a:expected_count

    " if the number of arguments provided is exactly one less than the
    " expected number, we'll use the current buffer file path as the first
    " file path
    if l:args_len == a:expected_count - 1
        let l:current = fops#utils#get_current_file()
        
        " make sure the file actually exists (if the check list requires this
        " check to be performed)
        if get(a:check_list, 0) &&
         \ !fops#utils#path_is_file(l:current) &&
         \ !fops#utils#path_is_dir(l:current)
            let l:errmsg = "The current buffer's file path (" .
                         \ l:current . ') is not a valid file or directory.'
            call fops#utils#panic(l:errmsg)
        endif

        call add(l:paths, l:current)
        let l:check_list_idx += 1
        let l:paths_remaining -= 1
    endif

    " add all arguments to the resulting list, while ensuring they each are
    " valid files
    for l:i in range(l:paths_remaining)
        let l:path = get(l:args, l:i)

        " if required, make sure the current file path exists
        if get(a:check_list, l:check_list_idx)
            let l:path = expand(l:path)
            if !fops#utils#path_is_file(l:path) && !fops#utils#path_is_dir(l:path)
                let l:errmsg = "The provided file path (" .
                             \ l:path . ') is not a valid file or directory.'
                call fops#utils#panic(l:errmsg)
            endif
        endif

        call add(l:paths, l:path)
        let l:check_list_idx += 1
    endfor

    " by the time we're done, we should have added exactly the number
    " requested by `expected_count`
    call fops#utils#sanity(len(l:paths) == a:expected_count)
    return l:paths
endfunction

" Returns the user-specific register name. It's retrieved from the
" `--register` argument, or defaults to the unnamed register.
function! s:get_register(parser) abort
    let l:reg_input = argonaut#argparser#get_arg(a:parser, '-r')
    if len(reg_input) == 0
        return fops#utils#reg_lookup('"')
    endif
    let l:reg_input = l:reg_input[0]

    " lookup the register name with the user's input, and throw an error if an
    " invalid name was given
    let l:reg = fops#utils#reg_lookup(l:reg_input)
    if l:reg is v:null
        let l:errmsg = 'Invalid register name: "' . l:reg_input . '".'
        call fops#utils#panic(l:errmsg)
    endif

    return l:reg
endfunction

" Takes in an input value from one of the Rename commands and ensures it
" doesn't have a dirname (meaning, it is only a basename and nothing else).
function! s:check_rename_input(str) abort
    " if there is no dirname, AND the string doesn't contain any delimeters,
    " we're good to go
    let l:dirname = fops#utils#path_get_dirname(a:str)
    if (len(l:dirname) == 0 || fops#utils#str_cmp(l:dirname, '.')) &&
     \ match(a:str, '/') == -1
        return
    endif

    " otherwise, throw an error
    let l:errmsg = 'The provided rename value ("' . a:str . '") must not ' .
                 \ 'contain any directories or path delimeters.'
    call fops#utils#panic(l:errmsg)
endfunction


" =============================== File Command =============================== "
let s:file_argset = argonaut#argset#new([s:arg_help])

" Tab completion helper function for the path command.
function! fops#commands#file_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_argset)
endfunction

" Main function for the path command.
function! fops#commands#file(input) abort
    let l:parser = argonaut#argparser#new(s:file_argset)
    try
        call fops#utils#print_debug('Executing the file command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source file
        let l:src = s:get_inputs(l:parser, 1, [1])[0]
        call fops#utils#print_debug('Source file: ' . l:src)

        " display the file's path
        let l:msg = 'File:       ' . l:src
        call fops#utils#print(l:msg)
        
        " display the file's size
        let l:size = fops#utils#file_get_size(l:src)
        let l:size_str = fops#utils#format_file_size(l:size)
        let l:msg = 'Size:       ' . l:size . ' bytes (' . l:size_str . ')'
        call fops#utils#print(l:msg)

        " display information about the the file's contents
        let l:type = fops#utils#file_get_info(l:src)
        let l:msg = 'Content:    ' . l:type
        call fops#utils#print(l:msg)
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction

" ============================ File Path Command ============================= "
let s:file_path_argset = argonaut#argset#new([s:arg_help])

" Tab completion helper function for the path command.
function! fops#commands#file_path_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_path_argset)
endfunction

" Main function for the path command.
function! fops#commands#file_path(input) abort
    let l:parser = argonaut#argparser#new(s:file_path_argset)
    try
        call fops#utils#print_debug('Executing the file-path command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source file and display the path
        let l:src = s:get_inputs(l:parser, 1, [1])[0]
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print(expand(l:src))
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Type Command ============================= "
let s:file_type_argset = argonaut#argset#new([s:arg_help])

" Tab completion helper function for the type command.
function! fops#commands#file_type_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_type_argset)
endfunction

" Main function for the type command.
function! fops#commands#file_type(input) abort
    let l:parser = argonaut#argparser#new(s:file_type_argset)
    try
        call fops#utils#print_debug('Executing the file-type command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source file to examine
        let l:src = s:get_inputs(l:parser, 1, [1])[0]
        call fops#utils#print_debug('Source file: ' . l:src)

        " retrieve file information and display it
        let l:info = fops#utils#file_get_info(l:src)
        call fops#utils#print(l:info)
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Size Command ============================= "
let s:file_size_argset = argonaut#argset#new([s:arg_help])

" Tab completion helper function for the size command.
function! fops#commands#file_size_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_size_argset)
endfunction

" Main function for the size command.
function! fops#commands#file_size(input) abort
    let l:parser = argonaut#argparser#new(s:file_size_argset)
    try
        call fops#utils#print_debug('Executing the file-size command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source file to examine
        let l:src = s:get_inputs(l:parser, 1, [1])[0]
        call fops#utils#print_debug('Source file: ' . l:src)

        " retrieve file size and display it
        let l:size = fops#utils#file_get_size(l:src)
        let l:size_str = fops#utils#format_file_size(l:size)
        let l:msg = 'File "' . l:src . '" contains ' . l:size . ' bytes. (' .
                  \ l:size_str . ')'
        call fops#utils#print(l:msg)
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Find Command ============================= "
let s:file_find_argset = argonaut#argset#new([s:arg_help, s:arg_edit])

" Tab completion helper function for the find command.
function! fops#commands#file_find_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_find_argset)
endfunction

" Main function for the find command.
function! fops#commands#file_find(input) abort
    let l:parser = argonaut#argparser#new(s:file_find_argset)
    try
        call fops#utils#print_debug('Executing the file-find command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
        
        " retrieve two inputs; the source file to search from, and the search
        " query to search for
        let l:inputs = s:get_inputs(l:parser, 2, [1, 0])
        let l:src = l:inputs[0]
        let l:query = l:inputs[1]

        " if the source file is a file (and not a directory), grab its parent
        " directory to search from
        if fops#utils#path_is_file(l:src)
            let l:src = fops#utils#path_get_dirname(l:src)
        endif

        call fops#utils#print_debug('Search directory: ' . l:src)
        call fops#utils#print_debug('Search query: ' . l:query)

        let l:pending_msg = 'Searching directory "' . l:src .
                          \ '" for files matching "' . l:query . '"...'
        call fops#utils#print_raw(l:pending_msg)

        " search for the file and quit early if no matches were found
        let l:matches = fops#utils#file_find(l:src, l:query)
        let l:matches_len = len(l:matches)
        if l:matches_len == 0
            call fops#utils#print_raw_clear()
            call fops#utils#print('No matches found within "' . l:src . '".')
            return
        endif

        " otherwise, display all matches to the user (if we only have one
        " match, just spit out the file name and nothing else)
        if l:matches_len == 1
            call fops#utils#print(l:matches[0])
        else
            let l:found_msg = 'Found ' . l:matches_len . ' match' .
                            \ (l:matches_len == 1 ? ':' : 'es:')
            call fops#utils#print_raw_clear()
            call fops#utils#print(l:found_msg)
            for l:idx in range(l:matches_len)
                let l:match = l:matches[l:idx]
                call fops#utils#print('' . (l:idx + 1) . '. ' . l:match)
            endfor
        endif

        " if the user specified the `--edit` argument, we'll open one of the
        " matches in the current buffer
        if argonaut#argparser#has_arg(l:parser, '-e')
            " by default, we'll assume only one match was found
            let l:selection = l:matches[0]

            " otherwise, we'll ask the user to specify which of the matches
            " should be opened in the current buffer
            if l:matches_len > 1
                let l:input_msg = 'Which file would you like to edit? ' .
                                \ '(enter a value from 1 to ' . l:matches_len .
                                \ ') '
                let l:match_idx = fops#utils#input_number_values(l:input_msg, range(1, l:matches_len))
                let l:selection = l:matches[l:match_idx - 1]
            endif
            
            " update the current buffer with the selection
            let l:buffer_updated = s:retarget_current_buffer(l:selection)
            if l:buffer_updated
                if fops#config#get('show_verbose_prints')
                    let l:msg = 'Buffer updated to edit file "' .
                              \ l:selection . '".'
                    call s:print_verbose(l:msg)
                endif
            endif
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================== Delete Command ============================== "
let s:file_delete_argset = argonaut#argset#new([s:arg_help, s:arg_edit])

" Tab completion helper function for the delete command.
function! fops#commands#file_delete_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_delete_argset)
endfunction

" Main function for the delete command.
function! fops#commands#file_delete(input) abort
    let l:parser = argonaut#argparser#new(s:file_delete_argset)
    try
        call fops#utils#print_debug('Executing the file-delete command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the target file
        let l:file = s:get_inputs(l:parser, 1, [1])[0]
        call fops#utils#print_debug('File to delete: ' . l:file)

        " confirm with the user that they want to go through with the
        " deletion. If they say no, return early
        if fops#utils#path_is_file(l:file) && fops#config#get('prompt_for_delete_file')
            let l:msg = 'Are you sure you want to delete the file: "' . 
                      \ l:file . '"? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        elseif fops#utils#path_is_dir(l:file) && fops#config#get('prompt_for_delete_dir')
            let l:msg = 'Are you sure you want to delete the directory: "' .
                      \ l:file . '" and all files within it? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        " attempt to delete the file
        call fops#utils#file_delete(l:file)

        " if the user requested it, update the buffer to point at an empty
        " buffer
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, v:null)
        
        " show a success message
        call fops#utils#print('Deletion successful.')
        if fops#config#get('show_verbose_prints') && l:buffer_updated
            call s:print_verbose('Buffer updated to edit an empty buffer.')
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Copy Command =============================== "
let s:file_copy_argset = argonaut#argset#new([s:arg_help, s:arg_edit])

" Tab completion helper function for the copy command.
function! fops#commands#file_copy_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_copy_argset)
endfunction

" Main function for the copy command.
function! fops#commands#file_copy(input) abort
    let l:parser = argonaut#argparser#new(s:file_copy_argset)
    try
        call fops#utils#print_debug('Executing the file-copy command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source and destination files to operate on
        let l:files = s:get_inputs(l:parser, 2, [1, 0])
        let l:src = l:files[0]
        let l:dst = expand(l:files[1])
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print_debug('Destination file: ' . l:dst)

        " if the destination file already exists, confirm with the user that
        " it's OK to overwrite it
        if fops#utils#path_is_file(l:dst) && fops#config#get('prompt_for_overwrite_file')
            let l:msg = 'File "' . l:dst . '" already exists. Overwrite? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        " attempt to copy the file
        call fops#utils#file_copy(l:src, l:dst)

        " if the user requested it, update the current buffer to edit the copied file
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:dst)
        
        " show a success message
        call fops#utils#print('Copy from "' . l:src . '" to "' . l:dst . '" successful.')
        if fops#config#get('show_verbose_prints') &&l:buffer_updated
            let l:msg = 'Buffer updated to edit new file "' . l:dst . '".'
            call s:print_verbose(l:msg)
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Move Command =============================== "
let s:file_move_argset = argonaut#argset#new([s:arg_help, s:arg_edit])

" Tab completion helper function for the move command.
function! fops#commands#file_move_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_move_argset)
endfunction

function! fops#commands#file_move(input) abort
    let l:parser = argonaut#argparser#new(s:file_move_argset)
    try
        call fops#utils#print_debug('Executing the file-move command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source and destination files to operate on
        let l:files = s:get_inputs(l:parser, 2, [1, 0])
        let l:src = l:files[0]
        let l:dst = expand(l:files[1])
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print_debug('Destination file: ' . l:dst)

        " if the destination file already exists, confirm with the user that
        " it's OK to overwrite it
        if fops#utils#path_is_file(l:dst) && fops#config#get('prompt_for_overwrite_file')
            let l:msg = 'File "' . l:dst . '" already exists. Overwrite? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        " attempt to move the file
        call fops#utils#file_move(l:src, l:dst)

        " if the user requested it, update the current buffer to edit the copied file
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:dst)
        
        " show a success message
        call fops#utils#print('Move from "' . l:src . '" to "' . l:dst . '" successful.')
        if fops#config#get('show_verbose_prints') && l:buffer_updated
            let l:msg = 'Buffer updated to edit relocated file "' . l:dst . '".'
            call s:print_verbose(l:msg)
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================== Rename Command ============================== "
" This argument indicates that the user wishes to rename the name, *excluding*
" the extension.
let s:arg_rename_name = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_rename_name, argonaut#argid#new('r', 'n'))
call argonaut#arg#add_argid(s:arg_rename_name, argonaut#argid#new('-', 'rn'))
call argonaut#arg#add_argid(s:arg_rename_name, argonaut#argid#new('--', 'rename-name'))
call argonaut#arg#set_description(s:arg_rename_name,
    \ "Renames the file's name, while keeping its extension as-is."
\ )

let s:arg_rename_ext = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_rename_ext, argonaut#argid#new('r', 'e'))
call argonaut#arg#add_argid(s:arg_rename_ext, argonaut#argid#new('-', 're'))
call argonaut#arg#add_argid(s:arg_rename_ext, argonaut#argid#new('--', 'rename-ext'))
call argonaut#arg#add_argid(s:arg_rename_ext, argonaut#argid#new('--', 'rename-extension'))
call argonaut#arg#set_description(s:arg_rename_ext,
    \ "Renames the file's extension, while keeping the name as-is."
\ )

let s:file_rename_argset = argonaut#argset#new([s:arg_help, s:arg_edit])
call argonaut#argset#add_arg(s:file_rename_argset, s:arg_rename_name)
call argonaut#argset#add_arg(s:file_rename_argset, s:arg_rename_ext)

" Tab completion helper function for the rename command.
function! fops#commands#file_rename_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_rename_argset)
endfunction

function! fops#commands#file_rename(input) abort
    let l:parser = argonaut#argparser#new(s:file_rename_argset)
    try
        call fops#utils#print_debug('Executing the file-rename command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source files and new name input
        let l:files = s:get_inputs(l:parser, 2, [1, 0])
        let l:src = l:files[0]
        let l:name = l:files[1]
        call s:check_rename_input(l:name)
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print_debug('Input value: ' . l:name)

        " by default, we'll rename the entire basename. Check the user's input
        " arguments in case something else was chosen
        let l:dst = fops#utils#path_set_basename(l:src, l:name)
        if argonaut#argparser#has_arg(l:parser, '--rename-name')
            " if only the name is to be changed, we'll keep the extension
            let l:old_ext = fops#utils#path_get_extension(l:src)
            let l:dst = fops#utils#path_remove_extension(l:src) . '.' . l:old_ext
            call fops#utils#print_debug('New file path ' .
                                      \ '(new name, same extension): "' .
                                      \ l:dst . '"')
        elseif argonaut#argparser#has_arg(l:parser, '--rename-extension')
            " if only the extension is to be changed, keep the original name
            let l:old_name = fops#utils#path_get_basename(l:src)
            let l:old_name = fops#utils#path_remove_extension(l:old_name)
            
            " modify the input string to ensure it begins with a dot
            let l:ext = l:name
            if !fops#utils#str_begins_with(l:name, '.')
                let l:ext = '.' . l:ext
            endif
            
            let l:dst = fops#utils#path_set_basename(l:src, l:old_name . l:ext)
            call fops#utils#print_debug('New file path ' .
                                      \ '(new name, same extension): "' .
                                      \ l:dst . '"')
        endif

        " if the destination file already exists, confirm with the user that
        " it's OK to overwrite it
        if fops#utils#path_is_file(l:dst) && fops#config#get('prompt_for_overwrite_file')
            let l:msg = 'File "' . l:dst . '" already exists. Overwrite? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        " attempt to rename the file (i.e. set its basename)
        call fops#utils#file_move(l:src, l:dst)

        " if the user requested it, update the current buffer to edit the copied file
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:dst)
        
        " show a success message
        call fops#utils#print('Rename to "' . l:dst . '" successful.')
        if fops#config#get('show_verbose_prints') &&l:buffer_updated
            let l:msg = 'Buffer updated to edit renamed file "' . l:dst . '".'
            call s:print_verbose(l:msg)
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Yank Command =============================== "
" The `-r`/`--register` argument is used by the yank command(s) in this plugin.
" This allows the user to specify the register to store the yanked text into.
" (By default, the unnamed/clipboard register is used.)
let s:arg_register = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_register, argonaut#argid#new('-', 'r'))
call argonaut#arg#add_argid(s:arg_register, argonaut#argid#new('--', 'register'))
call argonaut#arg#set_description(s:arg_register,
    \ 'Sets the register to store yanked text into. (The default is the unnamed register.)'
\ )
call argonaut#arg#set_value_required(s:arg_register, 1)
call argonaut#arg#set_value_hint(s:arg_register, 'REGISTER_NAME')

" This argument indicates that the user wishes to yank the full file path.
let s:arg_yank_path = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('y', 'p'))
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('-', 'yp'))
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('--', 'yank-path'))
call argonaut#arg#set_description(s:arg_yank_path,
    \ "Yanks the file's full path."
\ )

" This argument indicates that the user wishes to yank the file's basename.
let s:arg_yank_basename = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('y', 'b'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('y', 'n'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('-', 'yb'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('-', 'yn'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-name'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-base'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-basename'))
call argonaut#arg#set_description(s:arg_yank_basename,
    \ "Yanks the file's basename (the string appearing after the final path delimeter)."
\ )

" This argument indicates that the user wishes to yank the file's dirname.
let s:arg_yank_dirname = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('y', 'd'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('-', 'yd'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('--', 'yank-dir'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('--', 'yank-dirname'))
call argonaut#arg#set_description(s:arg_yank_dirname,
    \ "Yanks the file's dirname (the full string appearing before the final path delimeter)."
\ )

" This argument indicates that the user wishes to yank the file's extension.
let s:arg_yank_ext = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('y', 'e'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('-', 'ye'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('--', 'yank-ext'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('--', 'yank-extension'))
call argonaut#arg#set_description(s:arg_yank_ext,
    \ "Yanks the file's extension."
\ )


let s:file_yank_argset = argonaut#argset#new([s:arg_help, s:arg_register])
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_path)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_basename)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_dirname)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_ext)

" Tab completion helper function for the yank command.
function! fops#commands#file_yank_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_yank_argset)
endfunction

function! fops#commands#file_yank(input) abort
    let l:parser = argonaut#argparser#new(s:file_yank_argset)
    try
        call fops#utils#print_debug('Executing the file-yank command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
        
        " retrieve the source file and the register the user wants to write to
        let l:path = s:get_inputs(l:parser, 1, [1])[0]
        let l:reg = s:get_register(l:parser)
        call fops#utils#print_debug('Source file: ' . l:path)
        call fops#utils#print_debug('Target register: ' . l:reg)
        
        " by default, we'll write the entire file path into the register
        let l:reg_val = l:path
        let l:success_msg = 'File path "' . l:reg_val . '" '

        " but before doing so, examine the various possible arguments to
        " determine if the user wants a specific portion of the file path to
        " written into the register
        if argonaut#argparser#has_arg(l:parser, '--yank-path')
            let l:reg_val = l:path
            let l:success_msg = 'File path "' . l:reg_val . '" '
        elseif argonaut#argparser#has_arg(l:parser, '--yank-basename')
            let l:reg_val = fops#utils#path_get_basename(l:path)
            let l:success_msg = 'File basename "' . l:reg_val . '" '
        elseif argonaut#argparser#has_arg(l:parser, '--yank-dirname')
            let l:reg_val = fops#utils#path_get_dirname(l:path)
            let l:success_msg = 'File dirname "' . l:reg_val . '" '
        elseif argonaut#argparser#has_arg(l:parser, '--yank-extension')
            let l:reg_val = fops#utils#path_get_extension(l:path)
            let l:success_msg = 'File extension "' . l:reg_val . '" '
        endif

        " write the selected value into the register
        call fops#utils#reg_write(l:reg, l:reg_val)

        " show a success message
        let l:msg = l:success_msg . 'written to register @' . l:reg . '.'
        call fops#utils#print(l:msg)
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Tree Command =============================== "
let s:file_tree_argset = argonaut#argset#new([s:arg_help, s:arg_edit])

" Tab completion helper function for the tree command.
function! fops#commands#file_tree_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_tree_argset)
endfunction

" Helper function that recursively iterates through the given root's files.
function! fops#commands#file_tree_traverse_helper(root, files, idx, prefix) abort
    let l:entries = fops#utils#dir_get_entries(a:root)
    
    let l:i = a:idx
    let l:entries_len = len(l:entries)
    for l:entry_idx in range(l:entries_len)
        let l:entry = l:entries[l:entry_idx]

        " get the file basename and format the index number
        let l:basename = fops#utils#path_get_basename(l:entry)
        let l:number = printf('%-10s', (l:i + 1) . '.')

        " decide on a prefix to print a tree-like structure
        let l:tree_prefix = a:prefix . ' ├─ '
        if l:entry_idx == l:entries_len - 1
            let l:tree_prefix = a:prefix . ' └─ '
        endif

        " build the final line string and print it
        let l:line = '' . l:number . ' ' . l:tree_prefix . l:basename
        call fops#utils#print(l:line)
        
        " increment the index and append to the list
        let l:i += 1
        call add(a:files, l:entry)

        " if the current entry is a directory, recursively call this function
        if fops#utils#path_is_dir(l:entry)
            let l:child_prefix = ' │  '
            if l:entry_idx == l:entries_len - 1
                let l:child_prefix = '    '
            endif
            
            " invoke the helper on the child
            let l:result = fops#commands#file_tree_traverse_helper(
                \ l:entry,
                \ a:files,
                \ l:i,
                \ a:prefix . l:child_prefix
            \ )

            " update the index based on the result
            let l:i = l:result[1]
        endif
    endfor

    return [a:files, l:i, a:prefix]
endfunction

" Helper function that displays a tree from the given directory.
" Returns a list of directories and files.
function! fops#commands#file_tree_traverse(dir) abort
    call fops#utils#print('File Tree: "' . a:dir . '"')
    let l:result = fops#commands#file_tree_traverse_helper(a:dir, [], 0, "")
    return l:result[0]
endfunction

function! fops#commands#file_tree(input) abort
    let l:parser = argonaut#argparser#new(s:file_tree_argset)
    try
        call fops#utils#print_debug('Executing the file-tree command.')

        " parse command-line arguments
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser)
            return
        endif
    
        " get the source file, and deduce a directory from it (if the source
        " file *is* a directory, we'll use that. If not, we'll use the source
        " file's parent directory)
        let l:src = s:get_inputs(l:parser, 1, [1])[0]
        if !fops#utils#path_is_dir(l:src)
            let l:src = fops#utils#path_get_dirname(l:src)
        endif
        call fops#utils#print_debug('Source directory: ' . l:src)

        " traverse the directory and print a tree
        let l:files = fops#commands#file_tree_traverse(l:src)

        " if the user requested it, prompt the user to select a file to edit
        if argonaut#argparser#has_arg(l:parser, '-e')
            let l:files_len = len(l:files)

            " build a message and prompt the user
            let l:msg = 'Which file would you like to edit? ' .
                      \ '(enter a value from 1 to ' . l:files_len . ') '
            let l:idx = fops#utils#input_number_values(l:msg, range(1, l:files_len))
            let l:selection = l:files[l:idx - 1]

            " update the current buffer with the selection
            let l:buffer_updated = s:retarget_current_buffer(l:selection)
            if l:buffer_updated
                if fops#config#get('show_verbose_prints')
                    let l:msg = 'Buffer updated to edit file "' .
                              \ l:selection . '".'
                    call s:print_verbose(l:msg)
                endif
            endif
        endif
    catch
        call s:maybe_show_help_menu(l:parser)
        call fops#utils#print_error(v:exception)
    endtry
endfunction

