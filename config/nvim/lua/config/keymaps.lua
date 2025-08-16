-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Make sure leader key is set (if not already set elsewhere)
vim.g.mapleader = " "  -- Sets space as leader key

-- Map terminal escape 
-- 't' is terminal mode
-- Using more explicit description in opts
vim.keymap.set("t", "<ESC>", "<C-\\><C-n>", { 
    noremap = true,
    silent = true,
    desc = "Exit terminal mode"
})
