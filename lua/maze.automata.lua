local Maze = {}

local GRID_WIDTH = 28
local GRID_HEIGHT = 31

-- Tile types
local EMPTY = 0
local WALL = 1
local DOT = 2
local POWER_PELLET = 3

-- Unicode characters for display
local CHARS = {
	[EMPTY] = "", -- Empty space
	[WALL] = "\x1b[38;5;240m|\x1b[0m", -- Gray Wall (█)
	[DOT] = "\x1b[38;5;15m·\x1b[0m", -- White Dot (·)
	[POWER_PELLET] = "\x1b[38;5;226m●\x1b[0m", -- Yellow Power Pellet (●)
}

-- ANSI color codes
local COLORS = {
	RESET = "\27[0m",
	BLUE = "\27[34m",
	YELLOW = "\27[33m",
	RED = "\27[31m",
}

function Maze:init()
	local pacman_looks = COLORS.YELLOW .. "🟢" .. COLORS.RESET

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

function Maze:generate_maze_ca()
	-- Initialize grid randomly
	for y = 1, GRID_HEIGHT do
		self.game.grid[y] = {}
		for x = 1, GRID_WIDTH do
			if x == 1 or x == GRID_WIDTH or y == 1 or y == GRID_HEIGHT then
				self.game.grid[y][x] = WALL -- Create a border
			else
				self.game.grid[y][x] = math.random() < 0.45 and WALL or EMPTY
			end
		end
	end

	-- Apply cellular automaton rules
	local iterations = 5
	for _ = 1, iterations do
		local new_grid = {}
		for y = 1, GRID_HEIGHT do
			new_grid[y] = {}
			for x = 1, GRID_WIDTH do
				local count = self:count_neighbors(x, y)
				if self.game.grid[y][x] == WALL then
					new_grid[y][x] = (count >= 4) and WALL or EMPTY
				else
					new_grid[y][x] = (count >= 5) and WALL or EMPTY
				end
			end
		end
		self.game.grid = new_grid
	end

	-- Ensure Maze's starting position is empty
	self.game.grid[self.game.pacman.y][self.game.pacman.x] = EMPTY

	-- Add dots and power pellets
	for y = 1, GRID_HEIGHT do
		for x = 1, GRID_WIDTH do
			if self.game.grid[y][x] == EMPTY and (x ~= self.game.pacman.x or y ~= self.game.pacman.y) then
				self.game.grid[y][x] = math.random() < 0.05 and POWER_PELLET or DOT
			end
		end
	end
end

function Maze:count_neighbors(x, y)
	local count = 0
	for dy = -1, 1 do
		for dx = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				local nx, ny = x + dx, y + dy
				if
					nx >= 1
					and nx <= GRID_WIDTH
					and ny >= 1
					and ny <= GRID_HEIGHT
					and self.game.grid[ny][nx] == WALL
				then
					count = count + 1
				end
			end
		end
	end
	return count
end

function Maze:display_terminal()
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

	print(display)
end

function Maze:create()
	Maze:init()
	Maze:generate_maze_ca()
	Maze:display_terminal()
end

Maze:create()

return Maze
