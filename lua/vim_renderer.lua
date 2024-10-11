local Renderer = {}

Renderer.render = function(opts, move_to_end)
	vim.api.nvim_buf_set_option(0, "modifiable", true)

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

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(0, "modifiable", false)

	if not move_to_end then
		return
	end

	local last_line = vim.api.nvim_buf_line_count(0)
	vim.api.nvim_win_set_cursor(0, { last_line, 0 })
end

return Renderer
