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

	-- self:generate_maze()
	-- self:remove_dead_ends()
	-- self:copy_maze()
end

local function in_bounds(nx, ny)
	return nx > 0 and nx <= GRID_WIDTH and ny > 0 and ny <= GRID_HEIGHT
end

function Pacman:generate_maze()
	-- Initialize grid with walls
	for y = 1, GRID_HEIGHT do
		self.game.grid[y] = {}
		for x = 1, GRID_WIDTH do
			self.game.grid[y][x] = WALL
		end
	end

	-- Create outer wall paths
	for y = 2, GRID_HEIGHT - 1 do
		self.game.grid[y][2] = EMPTY
		self.game.grid[y][GRID_WIDTH - 1] = EMPTY
	end
	for x = 2, GRID_WIDTH - 1 do
		self.game.grid[2][x] = EMPTY
		self.game.grid[GRID_HEIGHT - 1][x] = EMPTY
	end

	-- Create ghost spawn area (middle section)
	for y = 12, 19 do
		for x = 12, 17 do
			self.game.grid[y][x] = WALL
		end
	end

	-- DFS to generate paths
	local stack = {}
	local start_x, start_y = 3, 3 -- Starting point for DFS

	self.game.grid[start_y][start_x] = EMPTY
	table.insert(stack, { start_y, start_x })

	while #stack > 0 do
		local curr = stack[#stack]
		local y, x = curr[1], curr[2]

		local neighbours = self:get_neighbours(x, y)

		if #neighbours > 0 then
			local selected = neighbours[math.random(#neighbours)]
			local ny, nx = selected[1], selected[2]

			-- Connect current cell with the selected neighbour
			self.game.grid[ny][nx] = EMPTY
			self.game.grid[(y + ny) / 2][(x + nx) / 2] = EMPTY -- Remove wall between

			table.insert(stack, { ny, nx })
		else
			table.remove(stack)
		end
	end
end

function Pacman:remove_dead_ends()
	for y = 1, GRID_HEIGHT do
		for x = 1, GRID_WIDTH do
			if self.game.grid[y][x] == EMPTY and self:count_adjacent_empty(x, y) == 1 then
				-- Check if it can connect to another path
				if not self:can_connect_to_another_path(x, y) then
					self.game.grid[y][x] = WALL
				end
			end
		end
	end
end

function Pacman:count_adjacent_empty(x, y)
	local count = 0
	local directions = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } -- up, down, left, right

	for _, dir in ipairs(directions) do
		local nx, ny = x + dir[1], y + dir[2]
		if in_bounds(nx, ny) and self.game.grid[ny][nx] == EMPTY then
			count = count + 1
		end
	end

	return count
end

function Pacman:can_connect_to_another_path(x, y)
	local directions = { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } -- up, down, left, right

	for _, dir in ipairs(directions) do
		local nx, ny = x + dir[1], y + dir[2]
		if in_bounds(nx, ny) and self.game.grid[ny][nx] == EMPTY then
			return true
		end
	end

	return false
end

function Pacman:copy_maze()
	-- Create a new grid to hold the mirrored maze
	local new_grid = {}

	for y = 1, GRID_HEIGHT do
		new_grid[y] = {}
		for x = 1, GRID_WIDTH do
			if x <= GRID_WIDTH / 2 then
				new_grid[y][x] = self.game.grid[y][x] -- Copy original left
				new_grid[y][GRID_WIDTH - x + 1] = self.game.grid[y][x] -- Mirror to the right
			else
				new_grid[y][x] = self.game.grid[y][x] -- Keep right side as is (not needed but kept for clarity)
			end
		end
	end

	-- Replace the original grid with the new mirrored grid
	self.game.grid = new_grid

	-- Fill the maze with dots and power pellets
	for y = 1, GRID_HEIGHT do
		for x = 1, GRID_WIDTH do
			if self.game.grid[y][x] == EMPTY then
				if math.random() < 0.1 then
					self.game.grid[y][x] = POWER_PELLET
				else
					self.game.grid[y][x] = DOT
				end
			end
		end
	end
end

function Pacman:get_neighbours(x, y)
	local dirs = { { -2, 0 }, { 2, 0 }, { 0, 2 }, { 0, -2 } }
	local neighbours = {}

	for _, dir in ipairs(dirs) do
		local nx, ny = x + dir[1], y + dir[2]
		if in_bounds(nx, ny) and self.game.grid[ny][nx] == WALL then
			table.insert(neighbours, { ny, nx })
		end
	end

	return neighbours
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

-- Pacman:init()
-- Pacman:display_terminal()

function Pacman:generate_maze_v1()
	-- Everything is a wall
	-- Iteratively and randomly select neighbours, skipping 1
	-- we skip 1, to consider the presence of a wall, otherwize
	-- everything will be EMPTY

	for y = 1, GRID_HEIGHT do
		self.game.grid[y] = {}

		for x = 1, GRID_WIDTH do
			self.game.grid[y][x] = WALL
		end
	end

	local stack = {}
	local startx, starty = 2, 2

	self.game.grid[starty][startx] = EMPTY
	table.insert(stack, { starty, startx })

	-- run bfs to find all connected walls
	while #stack > 0 do
		local curr = stack[#stack]
		local cy, cx = curr[1], curr[2]

		local neighbours = self:get_neighbours(cx, cy)

		if #neighbours <= 0 then
			table.remove(stack)
		else
			local selected = neighbours[math.random(#neighbours)]
			local ny, nx = selected[1], selected[2]

			self.game.grid[ny][nx] = EMPTY
			-- We also need to connect the (cy, cx) with (ny, nx)
			self.game.grid[(cy + ny) / 2][(cx + nx) / 2] = EMPTY
			table.insert(stack, { ny, nx })
		end
	end

	-- fill will pellets and dot
	local empties = {}

	for y = 1, GRID_HEIGHT do
		for x = 1, GRID_WIDTH do
			if self.game.grid[y][x] ~= EMPTY then
				goto mark
			end

			table.insert(empties, { x, y })
			if math.random() < 0.1 then
				self.game.grid[y][x] = POWER_PELLET
			else
				self.game.grid[y][x] = DOT
			end

			::mark::
		end
	end

	-- set a random starting point
	-- if #empties > 0 then
	-- 	local random_pos = empties[math.random(#empties)]
	-- 	self.game.pacman.x = random_pos[1]
	-- 	self.game.pacman.y = random_pos[2]
	-- end
end

function Pacman:v1()
	Pacman:init()
	Pacman:generate_maze_v1()
	Pacman:display_terminal()
end

function Pacman:v2()
	Pacman:init()
	Pacman:generate_maze()
	Pacman:remove_dead_ends()
	Pacman:copy_maze()

	Pacman:display_terminal()
end

Pacman:v1()
Pacman:v2()

return Pacman
