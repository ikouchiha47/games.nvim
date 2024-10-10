local MineSweeper = {}

-- Grid Size and Number of Bombs

MineSweeper.icons = {
	active = "⬜", -- Cleared cell
	hidden = "⬛", -- Hidden cell
	bomb = "💣", -- Bomb
	flag = "⚑⚑", -- Flag
	cleared = "🟢",
}

local function totalBombs(size)
	return math.random(size, size * 2)
end

function MineSweeper:init(size)
	self.grid = {}
	self.size = size
	self.cursor = { x = 1, y = 1 }
	self.game_over = false
	self.game_start = false

	for y = 1, size do
		self.grid[y] = {}

		for x = 1, size do
			self.grid[y][x] = { bomb = false, revealed = false, flagged = false }
		end
	end

	MineSweeper:plant_bombs()
end

function MineSweeper:plant_bombs()
	local placed = 0
	while placed < totalBombs(self.size) do
		local x = math.random(1, self.size)
		local y = math.random(1, self.size)

		if not self.grid[y][x].bomb then
			self.grid[y][x].bomb = true
			placed = placed + 1
		end
	end
end

local function vim_render(opts)
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
end

function MineSweeper:get_grid_state()
	local display = ""

	for y = 1, self.size do
		for x = 1, self.size do
			local cell = self.grid[y][x]

			if self.cursor.x == x and self.cursor.y == y then
				display = display .. MineSweeper.icons.active .. " " -- Active cell
			elseif cell.flagged then
				display = display .. MineSweeper.icons.flag .. " "
			elseif not cell.revealed then
				display = display .. MineSweeper.icons.hidden .. " "
			elseif cell.bomb then
				self.game_over = true
				display = display .. MineSweeper.icons.bomb .. " "
			else
				display = display .. MineSweeper.icons.cleared .. " " -- Just an empty space for cleared cells
			end
		end

		display = display .. "\n"
	end

	return display
end

function MineSweeper:display()
	if self.game_over then
		return
	end

	if not self.game_start then
		return
	end

	local display = self:get_grid_state()

	if self.game_over then
		vim_render({
			vim.split(display, "\n"),
			"Woohoo!! You blew up the house!",
			"Restart with :MineSweeper",
		})
		return
	end

	vim_render(vim.split(display, "\n"))
end

function MineSweeper:reveal_cell()
	local y = self.cursor.y
	local x = self.cursor.x

	local chosen = self.grid[y][x]

	if chosen.revealed then
		return
	end

	chosen.revealed = true
end

function MineSweeper:flag_cell()
	local y = self.cursor.y
	local x = self.cursor.x

	local chosen = self.grid[y][x]

	if chosen.revealed or chosen.flagged then
		return
	end

	chosen.flagged = true
end

function MineSweeper:is_bomb(x, y)
	local chosen = self.grid[y][x]

	return chosen.revealed and chosen.bomb
end

function MineSweeper:start()
	self.game_start = true
end

function MineSweeper:has_started()
	return self.game_start
end

function MineSweeper:move_cursor(dx, dy)
	local new_x = self.cursor.x + dx
	local new_y = self.cursor.y + dy

	-- Make sure the cursor doesn't go out of bounds
	if new_x >= 1 and new_x <= self.size then
		self.cursor.x = new_x
	end
	if new_y >= 1 and new_y <= self.size then
		self.cursor.y = new_y
	end
end

local function remap_keys(buf, keychar, callback)
	local cb = {
		callback = callback,
		noremap = true,
		silent = true,
	}
	vim.api.nvim_buf_set_keymap(buf, "n", keychar, "", cb)
end

local function disable_arrows(buf)
	vim.api.nvim_buf_set_keymap(buf, "n", "<Up>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Down>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Left>", "<Nop>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Right>", "<Nop>", { noremap = true, silent = true })
end

function MineSweeper.setup()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)

	local size = math.random(4, 10)
	if size % 2 ~= 0 then
		size = size + 1 -- Cox odd + odd = even, duh!
	end

	disable_arrows(buf)

	remap_keys(buf, "h", function()
		MineSweeper:move_cursor(-1, 0)
		MineSweeper:display()
	end)

	remap_keys(buf, "j", function()
		MineSweeper:move_cursor(0, 1)
		MineSweeper:display()
	end)

	remap_keys(buf, "k", function()
		MineSweeper:move_cursor(0, -1)
		MineSweeper:display()
	end)

	remap_keys(buf, "l", function()
		MineSweeper:move_cursor(1, 0)
		MineSweeper:display()
	end)

	remap_keys(buf, "<Space>", function()
		MineSweeper:flag_cell()
		MineSweeper:display()
	end)

	remap_keys(buf, "<CR>", function()
		if not MineSweeper:has_started() then
			MineSweeper:start()
		else
			MineSweeper:reveal_cell()
		end

		MineSweeper:display()
	end)

	MineSweeper:init(size)

	vim_render({
		"Controls",
		"Directions: [h|j|k|l]",
		"Space: To flag a cell",
		"Enter<CR> to reveal the cell",
		"Enter to start",
	})
end

return MineSweeper

-- vim: ts=2 sts=2 sw=2 et
