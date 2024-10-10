local MineSweeper = {}

-- Grid Size and Number of Bombs

MineSweeper.icons = {
	hidden = "⬜", -- Hidden cell
	cleared = "⬛", -- Cleared cell
	bomb = "💣", -- Bomb
	flag = "⚑", -- Flag
}

local function totalBombs(size)
	return math.random(size, size + (size / 2))
end

function MineSweeper:init(size)
	self.grid = {}
	self.size = size

	for y = 1, size do
		self.grid[y] = {}

		for x = 1, size do
			self.grid[y][x] = { bomb = false, revealed = false, flagged = false }
		end
	end
end

function MineSweeper:plant_bombs()
	local placed = 0
	while placed < totalBombs(self.size) do
		local x = math.random(1, self.size)
		local y = math.random(1, self.size)

		if not self.grid[y][x].bomb then
			self.grid[y][x].bomb = true
		end

		placed = placed + 1
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

function MineSweeper:display()
	local display = ""

	for y = 1, MineSweeper.height do
		for x = 1, MineSweeper.width do
			local cell = MineSweeper.grid[y][x]
			if cell.flagged then
				display = display .. MineSweeper.icons.flag .. " "
			elseif not cell.revealed then
				display = display .. MineSweeper.icons.hidden .. " "
			elseif cell.bomb then
				display = display .. MineSweeper.icons.bomb .. " "
			else
				display = display .. MineSweeper.icons.cleared .. " "
			end
		end
		display = display .. "\n"
	end

	vim_render(vim.split(display, "\n"))
end

function MineSweeper:reveal_cell(x, y)
	local chosen = self.grid[y][x]

	if chosen.revealed or chosen.flagged then
		return
	end

	chosen.revealed = true
end

function MineSweeper:flag_cell(x, y)
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

function MineSweeper.setup()
	local size = math.random(10, 20)
	if size % 2 ~= 0 then
		size = size + 1 -- Cox odd + odd = even, duh!
	end

	MineSweeper:init(size)
end

-- vim: ts=2 sts=2 sw=2 et
