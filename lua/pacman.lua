local Pacman = {}

local GRID_WIDTH = 28
local GRID_HEIGHT = 31

-- Tile types
local EMPTY = 0
local WALL = 1
local DOT = 2
local POWER_PELLET = 3

-- Unicode characters for display
local CHARS = {
	[EMPTY] = "  ", -- Empty space
	-- [WALL] = "\x1b[38;5;240m█\x1b[0m", -- Gray Wall (█)
	[WALL] = "\x1b[38;5;240m|\x1b[0m", -- Gray Wall (█)
	[DOT] = "\x1b[38;5;15m·\x1b[0m", -- White Dot (·)
	[POWER_PELLET] = "\x1b[38;5;226m●\x1b[0m", -- Yellow Power Pellet (●)
}

CHARS[EMPTY] = CHARS[DOT]

-- Pacman Colors
local PACMAN_COLORS = {
	"\x1b[38;5;196m", -- Red
	"\x1b[38;5;51m", -- Cyan
	"\x1b[38;5;208m", -- Orange
	"\x1b[38;5;82m", -- Green
}

-- Game state

function Pacman:init()
	local color = PACMAN_COLORS[math.random(#PACMAN_COLORS)]
	local pacman_looks = color .. "🟢" .. "\x1b[0m"

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
	for y = 1, GRID_HEIGHT do
		self.game.grid[y] = {}

		for x = 1, GRID_WIDTH do
			self.game.grid[y][x] = WALL
		end
	end

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

function Pacman:display_terminal()
	local display = ""

	for x = 1, GRID_WIDTH do
		for y = 1, GRID_HEIGHT do
			local char = CHARS[self.game.grid[y][x]]
			if self.game.pacman.x == x and self.game.pacman.y == y then
				char = self.game.pacman.symbol
			end
			display = display .. char .. " "
		end
		display = display .. "\n"
	end

	print(display)
end

function Pacman:v3()
	Pacman:init()
	Pacman:connect()
	Pacman:display_terminal()
end

Pacman:v3()
return Pacman
