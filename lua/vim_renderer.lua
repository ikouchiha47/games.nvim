local Renderer = {}

Renderer.render = function(bufr, opts, move_to_end)
	vim.api.nvim_buf_set_option(bufr, "modifiable", true)

	local lines = {}
	for _, line in ipairs(opts) do
		if type(line) == "string" then
			table.insert(lines, line)
		elseif type(line) == "table" then
			for _, subline in ipairs(line) do
				table.insert(lines, subline)
			end
		end
	end

	vim.api.nvim_buf_set_lines(bufr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufr, "modifiable", false)

	if not move_to_end then
		return
	end

	local last_line = vim.api.nvim_buf_line_count(bufr)
	vim.api.nvim_win_set_cursor(bufr, { last_line, 0 })
end

return Renderer
