local Hangman = require("hangman")

vim.api.nvim_create_user_command("Hangman", Hangman.setup, {})

-- vim: ts=2 sts=2 sw=2 et
