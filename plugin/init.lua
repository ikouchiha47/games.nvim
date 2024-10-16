local Hangman = require("hangman")
local MineSweeper = require("minesweeper")
local Pacman = require("pacman")

vim.api.nvim_create_user_command("Hangman", Hangman.setup, {})
vim.api.nvim_create_user_command("MineSweeper", MineSweeper.setup, {})
vim.api.nvim_create_user_command("Pacman", Pacman.setup, {})

-- vim: ts=2 sts=2 sw=2 et
