local Hangman = {}

Hangman.words = { "neovim" }
Hangman.max_attempts = 6

Hangman.stages = {
	[0] = [[
    +---+
    |   |
        |
        |
        |
        |
    ========]],
	[1] = [[
    +---+
    |   |
    O   |
        |
        |
        |
    ========]],
	[2] = [[
    +---+
    |   |
    O   |
    |   |
        |
        |
    ========]],
	[3] = [[
    +---+
    |   |
    O   |
   /|   |
        |
        |
    ========]],
	[4] = [[
    +---+
    |   |
    O   |
   /|\  |
        |
        |
    ========]],
	[5] = [[
    +---+
    |   |
    O   |
   /|\  |
   /    |
        |
    ========]],
	[6] = [[
    +---+
    |   |
    X   |
   /|\  |
   / \  |
        |
    ========]],
}

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

	local last_line = vim.api.nvim_buf_line_count(0)
	vim.api.nvim_win_set_cursor(0, { last_line, 0 })
end

function Hangman:init()
	math.randomseed(os.time())
	self.secret = self.words[math.random(#self.words)]

	self.guessed = {}
	self.wrong_guesses = {}
	self.current_attempts = 0
	self.game_over = false
end

function Hangman:guess(letter)
	if self.game_over then
		return
	end

	if self.secret:find(letter) then
		self.guessed[letter] = true
	else
		if not vim.tbl_contains(self.wrong_guesses, letter) then
			table.insert(self.wrong_guesses, letter)
			self.current_attempts = self.current_attempts + 1
		end
	end

	if self:won() or self.current_attempts >= self.max_attempts then
		self.game_over = true
	end

	self:display()
end

function Hangman:won()
	for i = 1, #self.secret do
		local letter = self.secret:sub(i, i)

		if not self.guessed[letter] then
			return false
		end
	end
	return true
end

function Hangman:draw_stage(attempt)
	local stage_lines = {}
	for line in self.stages[attempt]:gmatch("[^\r\n]+") do
		table.insert(stage_lines, line)
	end

	return stage_lines
end

function Hangman:display()
	local display_word = ""

	for i = 1, #self.secret do
		local letter = self.secret:sub(i, i)

		if self.guessed[letter] then
			display_word = display_word .. letter .. " "
		else
			display_word = display_word .. "_ "
		end
	end

	local wrong_guesses = table.concat(self.wrong_guesses, " ")
	local attempts_left = self.max_attempts - self.current_attempts

	vim_render({
		" Hangman",
		"==========",
		display_word,
		"",
		"Missed: " .. wrong_guesses,
		"Attempts: " .. attempts_left,
		self:draw_stage(self.current_attempts),
		"",
	})

	if not self.game_over then
		return
	end

	if self:won() then
		vim_render({
			"Actual: " .. self.secret,
			"You Won!! Its always a good day to hang..",
		})
	else
		vim_render({
			"Actual: " .. self.secret,
			"",
			self:draw_stage(self.current_attempts),
			"",
			"Seesh You Lost!",
		})
	end

	vim.api.nvim_command("stopinsert")
end

Hangman.restart = function()
	Hangman.setup()
end

Hangman.setup = function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)

	-- Set up key mappings for letter input a to z
	for i = 97, 122 do
		local char = string.char(i)
		local cb = {
			callback = function()
				Hangman:guess(char)
			end,
			noremap = true,
			silent = true,
		}

		vim.api.nvim_buf_set_keymap(buf, "i", char, "", cb)
		vim.api.nvim_buf_set_keymap(buf, "o", char, "", cb)
	end

	vim.api.nvim_command("startinsert")

	Hangman:init()
	Hangman:display()

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)

	-- Display instructions
	vim_render({
		"Instructions:",
		"- Press any letter (a-z) to make a guess",
		"- To restart do :Hangman",
		"",
	})
end

return Hangman

-- vim: ts=2 sts=2 sw=2 et
