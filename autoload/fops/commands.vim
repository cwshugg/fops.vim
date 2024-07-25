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

" The `-s`/`--source` argument is used by several of the commands in this
" plugin. This allows the user to specify the source file to operate on. (By
" default, the source file is the one pointed at by the user's current
" buffer.)
let s:arg_source = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_source, argonaut#argid#new('-', 's'))
call argonaut#arg#add_argid(s:arg_source, argonaut#argid#new('--', 'source'))
call argonaut#arg#set_description(s:arg_source,
    \ 'Sets the source file to operate on. (The default is the file open in your current buffer.)'
\ )
call argonaut#arg#set_value_required(s:arg_source, 1)
call argonaut#arg#set_value_hint(s:arg_source, 'FILE_PATH')


" ================================= Helpers ================================== "
" Prints a success message. The print only occurs if success messages are
" enabled in the plugin's config.
function! s:print_success(msg) abort
    if fops#config#get('show_success_prints')
        call fops#utils#print(a:msg)
    endif
endfunction

" Helper function that takes in an argparser object and argset, and shows the
" help menu if the `--help` argument (defined above) is specified. Returns
" true if the help menu was shown.
function! s:maybe_show_help_menu(parser, argset) abort
    " if `--help` was not provided, quit early
    if !argonaut#argparser#has_arg(a:parser, '-h')
        return v:false
    endif
    
    " show the argonaut built-in help menu
    call argonaut#argset#show_help(a:argset)
    return v:true
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

    " make sure the given file path is a valid file or directory
    if !fops#utils#path_is_file(a:path) && !fops#utils#path_is_dir(a:path)
        let l:errmsg .= 'The provided path (' . a:path .
                      \ ') is not a valid file or directory.'
        call fops#utils#panic(l:errmsg)
    endif

    " open the new file in the current buffer
    execute 'edit ' . a:path

    return v:true
endfunction

" Helper function that returns one of the following, in this order of
" priority:
"
" 1. The file path specified by the user via the `--source` argument.
" 2. The file path of the current buffer.
function! s:get_src_file(parser) abort
    let l:result = v:null
    let l:errmsg = ''

    " did the user provide the `--source` option?
    let l:source = argonaut#argparser#get_arg(a:parser, '-s')
    if len(l:source) > 0
        let l:result = l:source[0]
        let l:errmsg .= 'The provided path (' . l:result . ') '
    " if not, select the current buffer's file
    else
        let l:result = fops#utils#get_current_file()
        let l:errmsg .= "The current buffer's file path "
        let l:errmsg .= '(' . l:result . ') '
    endif

    " expand any environment variables or other symbols
    let l:result = expand(l:result)

    " make sure the path is a valid file or directory
    if !fops#utils#path_is_file(l:result) && !fops#utils#path_is_dir(l:result)
        let l:errmsg .= 'is not a valid file or directory.'
        call fops#utils#panic(l:errmsg)
    endif

    return l:result
endfunction

" Takes in an argument parser and searches for the destination file path
" provided by the user.
function! s:get_dst_file(...) abort
    let l:parser = a:1

    " if a 'do_expand' parameter is specified, grab it
    let l:do_expand = v:true
    if a:0 > 1
        let l:do_expand = a:2
    endif
    
    " if an error message is specified, grab it
    let l:errmsg = 'No destination file path was provided.'
    if a:0 > 2
        let l:errmsg = a:3
    endif

    " the destination file should be the first extra/unnamed argument provided
    " by the user
    let l:extras = argonaut#argparser#get_extra_args(l:parser)
    if len(l:extras) < 1
        call fops#utils#panic(l:errmsg)
    endif

    let l:result = l:extras[0]
    
    " expand any environment variables or other symbols
    if l:do_expand
        let l:result = expand(l:result)
    endif
    return l:result
endfunction

" Returns the user-specific register name. It's retrieved from the
" `--register` argument, or defaults to the unnamed register.
function! s:get_register(parser) abort
    let l:reg_input = argonaut#argparser#get_arg(a:parser, '-r')
    if len(reg_input) == 0
        return fops#utils#reg_lookup('"')
    endif

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


" ============================ File Path Command ============================= "
let s:file_path_argset = argonaut#argset#new([s:arg_help, s:arg_source])

" Tab completion helper function for the path command.
function! fops#commands#file_path_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_path_argset)
endfunction

" Main function for the path command.
function! fops#commands#file_path(input) abort
    try
        call fops#utils#print_debug('Executing the file-path command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_path_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_path_argset)
            return
        endif
    
        " get the source file and display the path
        let l:src = s:get_src_file(l:parser)
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print(expand(l:src))
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Info Command ============================= "
let s:file_info_argset = argonaut#argset#new([s:arg_help, s:arg_source])

" Tab completion helper function for the info command.
function! fops#commands#file_info_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_info_argset)
endfunction

" Main function for the info command.
function! fops#commands#file_info(input) abort
    try
        call fops#utils#print_debug('Executing the file-info command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_info_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_info_argset)
            return
        endif
    
        " get the source file to examine
        let l:src = s:get_src_file(l:parser)
        call fops#utils#print_debug('Source file: ' . l:src)

        " retrieve file information and display it
        let l:info = fops#utils#file_get_info(l:src)
        call fops#utils#print(l:info)
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Size Command ============================= "
let s:file_size_argset = argonaut#argset#new([s:arg_help, s:arg_source])

" Tab completion helper function for the size command.
function! fops#commands#file_size_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_size_argset)
endfunction

" Main function for the size command.
function! fops#commands#file_size(input) abort
    try
        call fops#utils#print_debug('Executing the file-size command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_size_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_size_argset)
            return
        endif
    
        " get the source file to examine
        let l:src = s:get_src_file(l:parser)
        call fops#utils#print_debug('Source file: ' . l:src)

        " retrieve file size and display it
        let l:size = fops#utils#file_get_size(l:src)
        let l:size_str = fops#utils#format_file_size(l:size)
        let l:msg = 'File "' . l:src . '" contains ' . l:size . ' bytes. (' .
                  \ l:size_str . ')'
        call fops#utils#print(l:msg)
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================ File Find Command ============================= "
let s:file_find_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the find command.
function! fops#commands#file_find_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_find_argset)
endfunction

" Main function for the find command.
function! fops#commands#file_find(input) abort
    try
        call fops#utils#print_debug('Executing the file-find command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_find_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_find_argset)
            return
        endif

        " retrieve the source file/directory; we'll interpret this as the
        " directory to search from. If this fails, use the current directory
        let l:src = v:null
        try
            let l:src = s:get_src_file(l:parser)
            if fops#utils#path_is_file(l:src)
                let l:src = fops#utils#path_get_dirname(l:src)
            endif
        catch
            let l:src = fops#utils#get_pwd()
        endtry
    
        " retrieve the first extra argument; we'll interpret this as the name
        " to search for
        let l:query = s:get_dst_file(l:parser, v:false, 'No search query was provided.')

        call fops#utils#print_debug('Search directory: ' . l:src)
        call fops#utils#print_debug('Search query: ' . l:query)

        " search for the file and quit early if no matches were found
        let l:matches = fops#utils#file_find(l:src, l:query)
        let l:matches_len = len(l:matches)
        if l:matches_len == 0
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
            let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:selection)
            if l:buffer_updated
                if fops#config#get('show_success_prints')
                    let l:msg = 'Buffer updated to edit file (' .
                              \ l:selection . ').'
                    call s:print_success(l:msg)
                endif
            endif
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================== Delete Command ============================== "
let s:file_delete_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the delete command.
function! fops#commands#file_delete_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_delete_argset)
endfunction

" Main function for the delete command.
function! fops#commands#file_delete(input) abort
    try
        call fops#utils#print_debug('Executing the file-delete command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_delete_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_delete_argset)
            return
        endif
    
        " get the target file
        let l:file = s:get_src_file(l:parser)
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
        if fops#config#get('show_success_prints')
            let l:msg = 'Deletion succeeded.'
            if l:buffer_updated
                let l:msg .= ' Buffer updated to edit an empty buffer.'
            endif
            call s:print_success(l:msg)
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Copy Command =============================== "
let s:file_copy_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the copy command.
function! fops#commands#file_copy_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_copy_argset)
endfunction

" Main function for the copy command.
function! fops#commands#file_copy(input) abort
    try
        call fops#utils#print_debug('Executing the file-copy command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_copy_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_copy_argset)
            return
        endif
    
        " get the source and destination files to operate on
        let l:src = s:get_src_file(l:parser)
        let l:dst = s:get_dst_file(l:parser)
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
        if fops#config#get('show_success_prints')
            let l:msg = 'Copy succeeded.'
            if l:buffer_updated
                let l:msg .= ' Buffer updated to edit new file (' . l:dst . ').'
            endif
            call s:print_success(l:msg)
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" =============================== Move Command =============================== "
let s:file_move_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the move command.
function! fops#commands#file_move_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_move_argset)
endfunction

function! fops#commands#file_move(input) abort
    try
        call fops#utils#print_debug('Executing the file-move command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_move_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_move_argset)
            return
        endif
    
        " get the source and destination files to operate on
        let l:src = s:get_src_file(l:parser)
        let l:dst = s:get_dst_file(l:parser)
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
        if fops#config#get('show_success_prints')
            let l:msg = 'Move succeeded.'
            if l:buffer_updated
                let l:msg .= ' Buffer updated to edit relocated file (' . l:dst . ').'
            endif
            call s:print_success(l:msg)
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ============================== Rename Command ============================== "
let s:file_rename_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the rename command.
function! fops#commands#file_rename_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_rename_argset)
endfunction

function! fops#commands#file_rename(input) abort
    try
        call fops#utils#print_debug('Executing the file-rename command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_rename_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_rename_argset)
            return
        endif
    
        " get the source files and new name
        let l:src = s:get_src_file(l:parser)
        let l:name = s:get_dst_file(l:parser, v:true, 'No new file name was provided.')
        call s:check_rename_input(l:name)
        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print_debug('New name: ' . l:name)


        " if the destination file already exists, confirm with the user that
        " it's OK to overwrite it
        let l:dst = fops#utils#path_set_basename(l:src, l:name)
        if fops#utils#path_is_file(l:dst) && fops#config#get('prompt_for_overwrite_file')
            let l:msg = 'File "' . l:dst . '" already exists. Overwrite? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        " attempt to rename the file (i.e. set its basename)
        let l:dst = fops#utils#file_rename(l:src, l:name)

        " if the user requested it, update the current buffer to edit the copied file
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:dst)
        
        " show a success message
        if fops#config#get('show_success_prints')
            let l:msg = 'Rename succeeded.'
            if l:buffer_updated
                let l:msg .= ' Buffer updated to edit renamed file (' . l:dst . ').'
            endif
            call s:print_success(l:msg)
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction


" ========================= Rename Extension Command ========================= "
let s:file_rename_extension_argset = argonaut#argset#new([s:arg_help, s:arg_edit, s:arg_source])

" Tab completion helper function for the rename extension command.
function! fops#commands#file_rename_extension_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_rename_extension_argset)
endfunction

function! fops#commands#file_rename_extension(input) abort
    try
        call fops#utils#print_debug('Executing the file-rename-extension command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_rename_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_rename_argset)
            return
        endif
    
        " get the source files and new extension
        let l:src = s:get_src_file(l:parser)
        let l:ext = s:get_dst_file(l:parser, v:true, 'No new file extension was provided.')
        call s:check_rename_input(l:ext)

        " sanitize the extension value, such that a dot is always at the
        " beginning of the file
        if !fops#utils#str_begins_with(l:ext, '.')
            let l:ext = '.' . l:ext
        endif

        call fops#utils#print_debug('Source file: ' . l:src)
        call fops#utils#print_debug('New extension: ' . l:ext)

        " build a full file name, including the new extension
        let l:name = fops#utils#path_remove_extension(l:src)
        let l:name = fops#utils#path_get_basename(l:name)
        let l:name = l:name . l:ext

        " if the destination file already exists, confirm with the user that
        " it's OK to overwrite it
        let l:dst = fops#utils#path_set_basename(l:src, l:name)
        if fops#utils#path_is_file(l:dst) && fops#config#get('prompt_for_overwrite_file')
            let l:msg = 'File "' . l:dst . '" already exists. Overwrite? (y/n) '
            if !fops#utils#input_yesno(l:msg)
                return
            endif
            echo ' '
        endif

        let l:dst = fops#utils#file_rename(l:src, l:name)

        " if the user requested it, update the current buffer to edit the copied file
        let l:buffer_updated = s:maybe_retarget_current_buffer(l:parser, l:dst)
        
        " show a success message
        if fops#config#get('show_success_prints')
            let l:msg = 'Extension rename succeeded.'
            if l:buffer_updated
                let l:msg .= ' Buffer updated to edit renamed file (' . l:dst . ').'
            endif
            call s:print_success(l:msg)
        endif
    catch
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
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('-', 'yp'))
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('--', 'yank-path'))
call argonaut#arg#add_argid(s:arg_yank_path, argonaut#argid#new('y', 'p'))
call argonaut#arg#set_description(s:arg_yank_path,
    \ "Yanks the file's full path."
\ )

" This argument indicates that the user wishes to yank the file's basename.
let s:arg_yank_basename = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('-', 'yb'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('-', 'yn'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-name'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-base'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('--', 'yank-basename'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('y', 'b'))
call argonaut#arg#add_argid(s:arg_yank_basename, argonaut#argid#new('y', 'n'))
call argonaut#arg#set_description(s:arg_yank_basename,
    \ "Yanks the file's basename (the string appearing after the final path delimeter)."
\ )

" This argument indicates that the user wishes to yank the file's dirname.
let s:arg_yank_dirname = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('-', 'yd'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('--', 'yank-dir'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('--', 'yank-dirname'))
call argonaut#arg#add_argid(s:arg_yank_dirname, argonaut#argid#new('y', 'd'))
call argonaut#arg#set_description(s:arg_yank_dirname,
    \ "Yanks the file's dirname (the full string appearing before the final path delimeter)."
\ )

" This argument indicates that the user wishes to yank the file's extension.
let s:arg_yank_ext = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('-', 'ye'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('--', 'yank-ext'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('--', 'yank-extension'))
call argonaut#arg#add_argid(s:arg_yank_ext, argonaut#argid#new('y', 'e'))
call argonaut#arg#set_description(s:arg_yank_ext,
    \ "Yanks the file's extension."
\ )


let s:file_yank_argset = argonaut#argset#new([s:arg_help, s:arg_source, s:arg_register])
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_path)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_basename)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_dirname)
call argonaut#argset#add_arg(s:file_yank_argset, s:arg_yank_ext)

" Tab completion helper function for the yank command.
function! fops#commands#file_yank_complete(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:file_yank_argset)
endfunction

function! fops#commands#file_yank(input) abort
    try
        call fops#utils#print_debug('Executing the file-yank command.')

        " parse command-line arguments
        let l:parser = argonaut#argparser#new(s:file_yank_argset)
        call argonaut#argparser#parse(l:parser, a:input)
        if s:maybe_show_help_menu(l:parser, s:file_yank_argset)
            return
        endif
        
        " retrieve the source file and the register the user wants to write to
        let l:path = s:get_src_file(l:parser)
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
        if fops#config#get('show_success_prints')
            let l:msg = l:success_msg . 'written to register @' . l:reg . '.'
            call s:print_success(l:msg)
        endif
    catch
        call fops#utils#print_error(v:exception)
    endtry
endfunction

