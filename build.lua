-- install lua dependencies
vim.schedule(function()
	local ok, luarocks = pcall(require, "luarocks-nvim.rocks")
	assert(ok, "Missing required dependency: vhyrro/luarocks.nvim")

	luarocks.ensure({
		"lua-curl ~> 0.3",
	})
end)
