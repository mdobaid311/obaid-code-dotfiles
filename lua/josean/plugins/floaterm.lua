return {
  {
    "akinsho/toggleterm.nvim",
    version = "*", -- Use "*" to automatically grab the latest stable version
    config = function()
      require("toggleterm").setup({
        size = 20, -- Default size for terminal window
        open_mapping = [[<C-t>]], -- Keybinding to toggle the terminal
        hide_numbers = true, -- Hide the number column in terminal buffers
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2, -- The degree of shading applied
        start_in_insert = true, -- Start terminal in insert mode
        insert_mappings = true, -- Use terminal mappings in insert mode
        persist_size = true,
        direction = "horizontal", -- Options: "horizontal", "vertical", "tab", "float"
        close_on_exit = true, -- Close the terminal window when the process exits
        shell = "pwsh.exe", -- Specify PowerShell as the shell
        float_opts = { -- Options for floating windows
          border = "curved", -- Border style
          winblend = 3,
        },
      })
    end,
  },
}
