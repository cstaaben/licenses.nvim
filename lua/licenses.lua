M = {}

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
	local http = require("socket.http")
	local ltn12 = require("ltn12")

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
		local r = {}
		local _, code, headers = http.request({
			url = link,
			method = "GET",
			sink = ltn12.sink.table(r),
			headers = {
				accept = "application/vnd.github+json",
				["X-GitHub-Api-Version"] = "2022-11-28",
			},
		})

		if code ~= 200 then
			error(string.format("error getting licenses; received %d response: %s", code, r))
			return {}
		end

		table.insert(results, {
			id = r.key,
			name = r.name,
			url = r.url,
			body = r.body,
			description = r.description,
		})

		link = string.match(headers.link, '<(.-)>; rel="next"')
		pages_remain = string.len(link) ~= 0
	end

	return results
end

local function center(str)
	local w = api.nvim_win_get_width(0)
	local shift = math.floor(w / 2) - str:len()
	return string.rep(" ", shift) .. str
end

M.update_view = function()
	api.nvim_buf_set_option(buf, "modifiable", true)

	local data = M.list()
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
end

local function set_mappings()
	local mappings = {
		["k"] = "move_cursor()",
		["q"] = "close_window()",
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

M.licenses = function()
	open_window()
	set_mappings()
	M.update_view()
	api.nvim_win_set_cursor(win, { 3, 0 })
end

return M
