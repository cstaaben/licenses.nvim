local function contains_next()
	local headers = {
		link = '<https://api.github.com/repositories/1300192/issues?per_page=2&page=2>; rel="next", <https://api.github.com/repositories/1300192/issues?per_page=2&page=7715>; rel="last"',
	}

	local matches = string.gmatch(headers.link, '<(.-)>; rel="next"')
	local i = 0
	for s in matches do
		print(string.format("%d %s", i, s))
		i = i + 1
	end

	print(string.match(headers.link, '<(.-)>; rel="next"'))
end

contains_next()
