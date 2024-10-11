local utils = {}

utils.disable_arrows = function(buf)
	vim.api.nvim_buf_set_keymap(buf, "n", "<Up>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Down>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Left>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Right>", "<Nop>", { noremap = true, silent = true })
end

utils.remap_keys = function(buf, keychar, callback)
	local cb = {
		callback = callback,
		noremap = true,
		silent = true,
	}

	vim.api.nvim_buf_set_keymap(buf, "n", keychar, "", cb)
end

return utils
