" The plugin maintains a global table/dictionary of file stack objects. Each
" buffer has the ability to have its own file stack. This file implements a
" global dictionary containing these fstacks.

" The main dictionary object.
if !exists('g:fops_table')
    let g:fops_table = {}
endif

" Takes in a buffer ID and returns a fstack object if the buffer is found
" within the table. Otherwise, v:null is returned.
function! fops#fstack#table#lookup(buffer_id) abort
    let l:bid = a:buffer_id
    return get(g:fops_table, l:bid, v:null)
endfunction

" Works similarly to `fops#fstack#table#lookup()`, except if the given buffer
" ID currently has no entry in the global table, one is created and inserted
" into the table. The object is returned.
function! fops#fstack#table#get(buffer_id) abort
    let l:bid = a:buffer_id
    let l:fstack = fops#fstack#table#lookup(l:bid)
    if l:fstack is v:null
        call fops#utils#print_debug('Creating new file stack object for buffer "' .
                                  \ l:bid . '".')

        " create a new fstack and assign it the given buffer ID
        let l:fstack = fops#fstack#stack#new()
        call fops#fstack#stack#set_buffer(l:fstack, l:bid)

        " insert into the table
        let g:fops_table[l:bid] = l:fstack
    endif

    return l:fstack
endfunction

