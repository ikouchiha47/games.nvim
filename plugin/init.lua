local Hangman = require("hangman")

vim.api.nvim_create_user_command("Hangman", Hangman.setup, {})
