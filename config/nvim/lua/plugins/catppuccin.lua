return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
        -- Optional: configure the flavor (latte, frappe, macchiato, mocha)
        require("catppuccin").setup({
            flavour = "mocha" -- or your preferred flavor
        })
        
        -- Set the colorscheme
        vim.cmd.colorscheme "catppuccin"
    end,
}
