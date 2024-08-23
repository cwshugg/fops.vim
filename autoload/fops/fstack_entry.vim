" Implements an individual file stack entry object, as described in
" `fstack.vim`.

" Template object for a single file stack entry.
let s:fstack_entry_template = {
    \ 'path': v:null,
    \ 'cursor_line': 1,
    \ 'cursor_col': 1,
\ }

" Creates and returns a new fstack entry object
function! fops#fstack_entry#new(...) abort
    let l:result = deepcopy(s:fstack_entry_template)

    " grab optional arguments
    if a:0 > 0
        let l:result.path = a:1
    endif
    if a:0 > 1
        let l:result.cursor_line = a:2
    endif
    if a:0 > 2
        let l:result.cursor_line = a:3
    endif

    return l:result
endfunction

" Returns the entry's path.
function! fops#fstack_entry#get_path(entry) abort
    return a:entry.path
endfunction

" Sets the entry's path.
function! fops#fstack_entry#set_path(entry, path) abort
    let a:entry.path = a:path
endfunction

" Returns the entry's cursor line.
function! fops#fstack_entry#get_cursor_line(entry) abort
    return a:entry.cursor_line
endfunction

" Sets the entry's path.
function! fops#fstack_entry#set_cursor_line(entry, line_number) abort
    let a:entry.cursor_line = a:line_number
endfunction

" Returns the entry's cursor column.
function! fops#fstack_entry#get_cursor_col(entry) abort
    return a:entry.cursor_col
endfunction

" Sets the entry's path.
function! fops#fstack_entry#set_cursor_col(entry, col_number) abort
    let a:entry.cursor_col = a:col_number
endfunction

