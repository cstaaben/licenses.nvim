" prevent duplicate loads
if exists("g:loaded_licenses") | finish | end

" save user copts
let s:save_cpo = &cpo
" reset copts to defaults
set cpo&vim

" highlights
hi def link LicensesHeader Number
hi def link LicensesSubHeader Identifier

command! Licenses lua require("licenses").licenses()

" reset user copts
let &cpo = s:save_cpo
unlet s:save_cpo

" set loaded
let g:loaded_licenses = 1

