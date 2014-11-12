scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:obj = {
\	"__variable" : {}
\}


function! s:obj.number()
	return self.__variable.bufnr
endfunction


function! s:obj.invoke(func, ...)
	let args = get(a:, 1, [])
	return call(a:func, [self.number()] + args)
endfunction


function! s:obj.name()
	return self.invoke("bufname")
endfunction


function! s:obj.get_variable(...)
	return self.invoke("getbufvar", a:000)
endfunction


function! s:obj.set_variable(...)
	return self.invoke("setbufvar", a:000)
endfunction


function! s:obj.get_option(name)
	return self.get_variable("&" . a:name)
endfunction


function! s:obj.set_option(name, var)
	return self.set_variable("&" . a:name, a:var)
endfunction


function! s:obj.winnr()
	return self.invoke("bufwinnr")
endfunction


function! s:obj.is_exists()
	return bufexists(self.number())
endfunction


function! s:obj.is_listed()
	return self.invoke("buflisted")
endfunction


function! s:obj.is_loaded()
	return self.invoke("bufloaded")
endfunction


function! s:obj.is_current()
	return self.number() == bufnr("%")
endfunction


function! s:obj.is_modifiable()
	return self.get_option("modifiable")
endfunction


function! s:obj.is_opened_in_current_tabpage()
	return self.winnr() != -1
endfunction


function! s:obj.tap()
	if !self.is_exists() || self.is_tapped()
		return
	endif
	let self.__variable.tap_bufnr = bufnr("%")
	split
	execute "b" self.number()
	return self.number()
endfunction


function! s:obj.untap()
	if !self.is_tapped()
		return
	endif
	quit
	silent! execute "buffer" self.__variable.tap_bufnr
	unlet self.__variable.tap_bufnr
	return self.number()
endfunction


function! s:obj.tap_modifiable(...)
	let force = get(a:, 1, 1)
	if !(self.is_modifiable() || force)
		return
	endif
	let result = self.tap()
	if result
		let self.__variable.modifiable = &modifiable
		set modifiable
	endif
	return result
endfunction


function! s:obj.untap_modifiable()
	if has_key(self.__variable, "modifiable")
		let &modifiable = self.__variable.modifiable
		unlet self.__variable.modifiable
		call self.untap()
	endif
endfunction


function! s:obj.is_tapped()
	return has_key(self.__variable, "tap_bufnr")
endfunction


function! s:obj.execute(cmd)
	if self.is_current()
		execute a:cmd
		return
	endif
	if self.tap()
		try
			execute a:cmd
		finally
			call self.untap()
		endtry
	endif

" 	let view = winsaveview()
" 	try
" 		noautocmd silent! execute "bufdo if bufnr('%') == " a:expr . ' | ' . string(a:cmd) . ' | endif'
" 	finally
" 		noautocmd silent! execute "buffer" bufnr
" 		call winrestview(view)
" 	endtry
endfunction


function! s:obj.setline(lnum, text, ...)
	" 	if has("python")
" 		return s:setbufline_if_python(a:expr, a:lnum, a:text)
" 	else
" 		return s:execute(bufnr(a:expr), "call setline(" . a:lnum . "," . string(a:text) . ")")
" 	endif

	let force = get(a:, 1, 0)
	if self.tap_modifiable(force)
		try
			call setline(a:lnum, a:text)
		finally
			call self.untap_modifiable()
		endtry
	endif
" 	return self.execute("call setline(" . a:lnum . "," . string(a:text) . ")")
endfunction


function! s:obj.clear(...)
	let force = get(a:, 1, 0)
	if self.tap_modifiable(force)
		try
			silent % delete _
		finally
			call self.untap_modifiable()
		endtry
	endif
endfunction


function! s:obj.getline(...)
	return self.invoke("getbufline", a:000)
endfunction


function! s:obj.open(...)
	let open_cmd = get(a:, 1, "")
	execute open_cmd
	execute "buffer" self.number()
endfunction


function! s:obj.set_name(name)
	return self.execute(":file " . string(a:name))
endfunction


function! s:make(expr)
	let obj = deepcopy(s:obj)
	let obj.__variable.bufnr = bufnr(a:expr)
	return obj
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
