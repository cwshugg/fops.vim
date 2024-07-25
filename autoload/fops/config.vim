" This file implements various fields and functions to allow users to
" configure the plugin.

" Internal configuration object. This stores all configuration fields & their
" values.
let s:fops_config = {
    \ 'show_success_prints': v:true,
    \ 'show_debug_prints': v:true,
    \ 'print_prefix': '',
    \ 'debug_print_prefix': 'FOPS-Debug: ',
    \ 'error_print_prefix': 'FOPS-Error: ',
    \ 'prompt_for_overwrite_file': v:true,
    \ 'prompt_for_delete_file': v:true,
    \ 'prompt_for_delete_dir': v:true,
\ }

" Helper function that checks the given field name against the dictionary.
function! s:config_check_field(field)
    if !has_key(s:fops_config, a:field)
        let l:errmsg = 'The given field ("' . a:field . '") ' .
                     \ 'is not a valid configuration field.'
        fops#utils#panic(l:errmsg)
    endif
endfunction

" Sets a configuration field.
function! fops#config#set(field, value)
    call s:config_check_field(a:field)
    let s:fops_config[a:field] = a:value
endfunction

" Retrieves a configuration field.
function! fops#config#get(field)
    call s:config_check_field(a:field)
    return s:fops_config[a:field]
endfunction

