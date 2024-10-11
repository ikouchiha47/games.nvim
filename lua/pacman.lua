local Renderer = require("vim_renderer")

local Pacman = {}

local GRID_WIDTH = 28
local GRID_HEIGHT = 31

-- Tile types
local EMPTY = 0
local WALL = 1
local DOT = 2
local POWER_PELLET = 3

-- Unicode characters for display
local TERM_CHARS = {
	[EMPTY] = "", -- Empty space
	[WALL] = "\x1b[38;5;240m|\x1b[0m", -- Gray Wall (█)
	[DOT] = "\x1b[38;5;15m·\x1b[0m", -- White Dot (·)
	[POWER_PELLET] = "\x1b[38;5;226m●\x1b[0m", -- Yellow Power Pellet (●)
}

local CHARS = {
	[EMPTY] = "", -- Empty space
	[WALL] = "|", -- Gray Wall (█)
	[DOT] = "·", -- White Dot (·)
	[POWER_PELLET] = "●", -- Yellow Power Pellet (●)
}

-- CHARS[EMPTY] = CHARS[DOT]

-- Pacman Colors
local PACMAN_COLORS = {
	"\x1b[38;5;196m", -- Red
	"\x1b[38;5;51m", -- Cyan
	"\x1b[38;5;208m", -- Orange
	"\x1b[38;5;82m", -- Green
}

-- Other Colors
local COLORS = {
	RESET = "\27[0m",
	BLUE = "\27[34m",
	YELLOW = "\27[33m",
	RED = "\27[31m",
}

-- Game state

function Pacman:init()
	-- local color = PACMAN_COLORS[math.random(#PACMAN_COLORS)]
	-- local pacman_looks = color .. "🟢" .. "\x1b[0m"
	local pacman_looks = "🟢"

	self.game = {
		pacman = { x = 14, y = 23, direction = "right", symbol = pacman_looks },
		ghosts = {
			{ x = 14, y = 11, color = "red" },
			{ x = 13, y = 14, color = "pink" },
			{ x = 14, y = 14, color = "cyan" },
			{ x = 15, y = 14, color = "orange" },
		},
		grid = {},
		score = 0,
		lives = 3,
	}

	for y = 1, GRID_HEIGHT do
		self.game.grid[y] = {}

		for x = 1, GRID_WIDTH do
			self.game.grid[y][x] = WALL
		end
	end
end

local function in_bounds(nx, ny)
	return nx > 0 and nx <= GRID_WIDTH and ny > 0 and ny <= GRID_HEIGHT
end

function Pacman:get_neighbours(x, y, visited)
	local dirs = { { -2, 0 }, { 2, 0 }, { 0, 2 }, { 0, -2 } }
	local neighbours = {}

	for _, dir in ipairs(dirs) do
		local nx, ny = x + dir[1], y + dir[2]
		if in_bounds(nx, ny) and not visited[ny * GRID_WIDTH + nx] then
			table.insert(neighbours, { ny, nx })
		end
	end

	return neighbours
end

function Pacman:connect()
	local stack = {}
	local visited = {}
	local startx, starty = self.game.pacman.x, self.game.pacman.y

	self.game.grid[starty][startx] = EMPTY
	table.insert(stack, { starty, startx })
	visited[starty * GRID_WIDTH + startx] = true

	-- run bfs to find all connected walls
	while #stack > 0 do
		local curr = stack[#stack]
		local cy, cx = curr[1], curr[2]

		local neighbours = self:get_neighbours(cx, cy, visited)

		if #neighbours <= 0 then
			table.remove(stack)
		else
			local selected = neighbours[math.random(#neighbours)]
			local ny, nx = selected[1], selected[2]

			self.game.grid[ny][nx] = EMPTY
			-- We also need to connect the (cy, cx) with (ny, nx)
			self.game.grid[(cy + ny) / 2][(cx + nx) / 2] = EMPTY
			table.insert(stack, { ny, nx })
			visited[ny * GRID_WIDTH + nx] = true
		end
	end
end

function Pacman:check_loop(x, y, directions, size)
	local success = false

	for i = 1, 4 do
		for _ = 1, size do
			local ny, nx = y + directions[i][1], x + directions[i][2]
			success = in_bounds(nx, ny)
			if not success then
				break
			end
			y, x = ny, nx
		end
		if not success then
			break
		end
	end

	return success
end

function Pacman:create_loops()
	local totalAreaPart = math.floor(GRID_WIDTH * GRID_HEIGHT * 0.005)
	local dirs = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

	local notPath = 0

	for _ = 1, totalAreaPart do
		local startx, starty = math.random(2, GRID_HEIGHT - 1), math.random(2, GRID_WIDTH - 1)
		local loopSize = math.random(3, 6)

		local success = Pacman:check_loop(startx, starty, dirs, loopSize)

		if not success then
			notPath = notPath + 1
			goto continue
		end

		local curx, cury = startx, starty

		for i = 1, 4 do
			for _ = 1, loopSize do
				self.game.grid[cury][curx] = EMPTY
				cury, curx = cury + dirs[i][1], curx + dirs[i][2]
			end
		end
		::continue::
	end

	-- print("totalAreaPart", totalAreaPart, "noPath", notPath)
end

function Pacman:pellete()
	-- local pacy, pacx = self.game.pacman.
	for y = 1, GRID_HEIGHT do
		for x = 1, GRID_WIDTH do
			if self.game.grid[y][x] == EMPTY then
				if math.random() < 0.06 then -- 5% chance for power pellets
					self.game.grid[y][x] = POWER_PELLET
				else
					self.game.grid[y][x] = DOT
				end
			end
		end
	end
end

function Pacman:move(dir)
	local ny, nx = self.game.pacman.y, self.game.pacman.x

	if dir == "top" then
		nx = nx - 1
	elseif dir == "down" then
		nx = nx + 1
	elseif dir == "left" then
		ny = ny - 1
	elseif dir == "right" then
		ny = ny + 1
	end

	if not in_bounds(nx, ny) then
		return
	end

	if self.game.grid[ny][nx] == WALL then
		return
	end

	self.game.pacman.y, self.game.pacman.x = ny, nx
end

function Pacman:render()
	local display = ""

	for x = 1, GRID_WIDTH do
		for y = 1, GRID_HEIGHT do
			local char = CHARS[self.game.grid[y][x]]
			if self.game.pacman.x == x and self.game.pacman.y == y then
				char = self.game.pacman.symbol
				display = display .. char .. " "
			else
				display = display .. char .. "  "
			end
		end
		display = display .. "\n"
	end

	return display
end

function Pacman:display_terminal()
	print(Pacman:render())
end

function Pacman:display()
	Renderer.render(vim.split(self:render(), "\n"))
end

Pacman.setup = function()
	local buf = vim.api.nvim_create_buf(false, true)
	local utils = require("utils")
	vim.api.nvim_set_current_buf(buf)

	utils.disable_arrows(buf)

	utils.remap_keys(buf, "h", function()
		Pacman:move("left")
		Pacman:display()
	end)

	utils.remap_keys(buf, "l", function()
		Pacman:move("right")
		Pacman:display()
	end)

	utils.remap_keys(buf, "j", function()
		Pacman:move("down")
		Pacman:display()
	end)

	utils.remap_keys(buf, "k", function()
		Pacman:move("top")
		Pacman:display()
	end)

	Pacman:create()
	Pacman:display()
end

function Pacman:create()
	math.randomseed(os.time())

	Pacman:init()
	Pacman:connect()
	Pacman:create_loops()
	Pacman:pellete()
	-- Pacman:display_terminal()
end

-- Pacman:create()

return Pacman
