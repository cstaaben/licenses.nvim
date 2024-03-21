" licenses.nvim - Neovim plugin to add license files and headers
" Copyright (C) 2024  Corbin Staaben <cstaaben@gmail.com>
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

