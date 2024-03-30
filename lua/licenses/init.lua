--[[
    licenses.nvim - Neovim plugin to add license files and headers
    Copyright (C) 2024  Corbin Staaben <cstaaben@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-]]
M = {}

M.config = {
	-- name to include on license headers
	name = "John Doe",
	-- email to include on license headers
	email = "john.doe@email.com",
}

local found_curl, curl = pcall(require, "cURL.safe")

local api = vim.api
local buf, win

local function open_window()
	buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

	api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- get dimensions
	local width = api.nvim_get_option("columns")
	local height = api.nvim_get_option("lines")

	-- calculate our floating window size
	local h = math.ceil(height * 0.8 - 4)
	local w = math.ceil(width * 0.8)

	-- and its starting position
	local row = math.ceil((height - h) / 2 - 1)
	local col = math.ceil((width - w) / 2)

	-- set some options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = w,
		height = h,
		row = row,
		col = col,
	}
	local border_opts = {
		style = "minimal",
		relative = "editor",
		width = w + 2,
		height = h + 2,
		row = row - 1,
		col = col - 1,
	}

	local border_buf = api.nvim_create_buf(false, true)

	local border_lines = { "╔" .. string.rep("═", w) .. "╗" }
	local middle_line = "║" .. string.rep(" ", w) .. "║"
	for _ = 1, h do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, "╚" .. string.rep("═", w) .. "╝")

	api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

	local _ = api.nvim_open_win(border_buf, true, border_opts)
	win = api.nvim_open_win(buf, true, opts)
	api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout!"' .. border_buf)

	api.nvim_win_set_option(win, "cursorline", true)
end

-- TODO: telescope plugin
-- TODO: investigate plenary.async for faster loading
M.list = function(id)
	if not found_curl then
		error("missing dependency lua-curl")
		return {}, false
	end

	local url = "https://api.github.com/licenses"
	if id ~= nil then
		url = url .. "?license=" .. id
	else
		url = url .. "?page=1"
	end

	local results = {}
	local link = url
	local pages_remain = false
	while pages_remain do
		local request = curl.easy_init()
		request:setopt({
			url = link,
			headers = {
				accept = "application/vnd.github+json",
				["X-GitHub-Api-Version"] = "2022-11-28",
			},
		})
		request:setopt_http_version(curl.HTTP_VERSION_1_1)

		local result_data = {}
		local result_headers = {}
		request:setopt_writefunction(table.insert, result_data)
		request:setopt_headerfunction(table.insert, result_headers)

		local ok, err = request.perform()
		if not ok then
			error("error making request: " .. err)
			return {}, false
		end
		local code = request:getinfo_response_code()

		if code ~= 200 then
			error(string.format("error getting licenses; received %d response: %s", code, result_data))
			return {}, false
		end

		table.insert(results, {
			id = result_data.key,
			name = result_data.name,
			url = result_data.url,
			body = result_data.body,
			description = result_data.description,
		})

		link = string.match(result_headers.link, '<(.-)>; rel="next"')
		pages_remain = string.len(link) ~= 0

		request:close()
	end

	return results, true
end

local function center(str)
	local w = api.nvim_win_get_width(0)
	local shift = math.floor(w / 2) - str:len()
	return string.rep(" ", shift) .. str
end

M.update_view = function()
	api.nvim_buf_set_option(buf, "modifiable", true)

	local data, ok = M.list()
	print("list: " .. ok)
	if not ok then
		return false
	end
	table.sort(data, function(a, b)
		return a.id:lower() < b.id:lower()
	end)

	api.nvim_buf_set_lines(buf, 0, -1, false, { center("M"), "" })
	api.nvim_buf_add_highlight(buf, -1, "LicenseHeader", 0, 0, -1)

	for i, license in ipairs(data) do
		api.nvim_buf_set_lines(
			buf,
			i + 1,
			-1,
			false,
			{ string.format("[%s] %s:", license.id, license.name), string.format("\t%s", license.description) }
		)

		api.nvim_buf_add_highlight(buf, -1, "LicenseSubHeader", i + 1, 0, -1)
	end

	api.nvim_buf_set_option(buf, "modifiable", false)

	return true
end

local function set_mappings()
	local mappings = {
		["k"] = "move_cursor()",
		["q"] = "close_window()",
		["H"] = "add_header()",     -- TODO: implement
		["i"] = "add_license_file()", -- TODO: implement
	}

	for k, v in pairs(mappings) do
		api.nvim_buf_set_keymap(
			buf,
			"n",
			k,
			string.format(':lua require("licenses").%s<cr>', v),
			{ silent = true, nowait = true, noremap = true }
		)
	end
end

M.move_cursor = function()
	local pos = math.max(3, api.nvim_win_get_cursor(win)[1] - 1)
	api.nvim_win_set_cursor(win, { pos, 0 })
end

M.close_window = function()
	api.nvim_win_close(win, true)
end

-- TODO: implement
M.update_headers_year = function() end

M.licenses = function()
	open_window()
	set_mappings()
	local ok = M.update_view()
	if not ok then
		M.close_window()
		return
	end
	api.nvim_win_set_cursor(win, { 3, 0 })
end

return M
