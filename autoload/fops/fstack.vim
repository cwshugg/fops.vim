" This file defines an API intended to be used by external Vim scripts/plugins
" to interact with the FOPS-internal file stacks for each unique buffer.

" Gets the ID number of the current buffer.
function! fops#fstack#get_buffer_id() abort
    return fops#utils#get_buffer_id()
endfunction

" Creates and returns a new file stack entry object representative of the
" buffer corresponding to the given buffer ID.
function! fops#fstack#get_buffer_entry(buffer_id) abort
    let l:entry = fops#fstack#entry#new()
    
    " get the buffer number from the given ID
    let l:buffer_num = fops#utils#get_buffer_number(a:buffer_id)
    
    " set attributes for the entry
    call fops#fstack#entry#set_path(l:entry, expand("#" . l:buffer_num . ":p"))
    call fops#fstack#entry#set_cursor_line(l:entry, getbufvar(a:buffer_id, 'line', 1))
    call fops#fstack#entry#set_cursor_col(l:entry, getbufvar(a:buffer_id, 'col', 1))
    return l:entry
endfunction

" Retrieves and returns the file stack objects that corresponds with the given
" buffer ID.
function! fops#fstack#get(buffer_id) abort
    let l:fs = fops#fstack#table#get(a:buffer_id)
    call fops#utils#sanity(l:fs isnot v:null)
    return l:fs
endfunction

" Returns the number of entries in the given buffer's file stack.
function! fops#fstack#size(buffer_id) abort
    let l:fs = fops#fstack#get(a:buffer_id)
    return fops#fstack#stack#size(l:fs)
endfunction

" Pushes the given fstack entry object onto the given buffer's file stack.
function! fops#fstack#push(buffer_id, entry) abort
    call fops#fstack#entry#verify(a:entry)
    let l:fs = fops#fstack#get(a:buffer_id)
    call fops#fstack#stack#push(l:fs, a:entry)
endfunction

" Pops the top entry off of the file stack and returns it.
function! fops#fstack#pop(buffer_id) abort
    let l:fs = fops#fstack#get(a:buffer_id)
    return fops#fstack#stack#pop(l:fs)
endfunction

" Returns the top entry off of the file stack (without popping it).
function! fops#fstack#peek(buffer_id) abort
    let l:fs = fops#fstack#get(a:buffer_id)
    return fops#fstack#stack#peek(l:fs)
endfunction

" Applies the given file stack entry to the buffer associated with the given
" ID. The buffer is updated to edit the file specified in the entry.
function! fops#fstack#apply(buffer_id, entry) abort
    " force Vim to focus on the window specified by the ID
    call win_gotoid(a:buffer_id)

    " update the buffer to edit the file in the given entry
    :silent execute 'edit ' . fops#fstack#entry#get_path(a:entry)

    " update the cursor accordingly
    call cursor(fops#fstack#entry#get_cursor_line(a:entry),
              \ fops#fstack#entry#get_cursor_col(a:entry))
endfunction

