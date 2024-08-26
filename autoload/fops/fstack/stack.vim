" This file implements a file stack, which is used by some of this plugin's
" comands to maintain a stack of files for a specific buffer.
"
" The idea with this 'file stack' is that the plugin user can call commands
" such as 'FilePush' and 'FilePop' to update the current buffer with files to
" edit, such that their previous file is opened back up after popping from the
" stack.

" Template object for a file stack.
" Contains a 'stack', which is just a vim script list treated as a stack data
" structure, as well as a 'buffer ID', which is used to associate
" the stack with a specific buffer.
let s:fstack_template = {
    \ 'buffer_id': v:null,
    \ 'stack': [],
\ }

" Creates a new file stack object.
function! fops#fstack#stack#new() abort
    let l:result = deepcopy(s:fstack_template)
    return l:result
endfunction

" Returns the stack's assigned buffer ID.
function! fops#fstack#stack#get_buffer(stack) abort
    return a:stack.buffer_id
endfunction

" Sets the stack's assigned buffer ID.
function! fops#fstack#stack#set_buffer(stack, bid) abort
    let a:stack.buffer_id = a:bid
endfunction

" Returns the number of entries in the stack.
function! fops#fstack#stack#size(stack) abort
    return len(a:stack.stack)
endfunction

" Pushes a fstack entry onto the stack.
function! fops#fstack#stack#push(stack, entry) abort
    call insert(a:stack.stack, a:entry, 0)
endfunction

" Pops the most recent entry from the stack. Returns v:null if the stack is
" empty.
function! fops#fstack#stack#pop(stack) abort
    if empty(a:stack.stack)
        return v:null
    endif
    return remove(a:stack.stack, 0)
endfunction

" Returns a reference to the entry at the top of the stack. Returns v:null if
" the stack is empty.
function! fops#fstack#stack#peek(stack) abort
    if empty(a:stack.stack)
        return v:null
    endif
    return a:stack.stack[0]
endfunction

