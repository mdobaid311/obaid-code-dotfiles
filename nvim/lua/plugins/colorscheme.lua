return {
	{
		"Shatur/neovim-ayu",
		config = function()
			require("ayu").setup({
				mirage = false, -- Set to true for `ayu-mirage`, false for `ayu-dark`
				overrides = {}, -- Optional overrides for highlights
			})
			vim.cmd("colorscheme ayu")
		end,
		lazy = false, -- Ensure it's loaded immediately
		priority = 1000, -- Ensure it loads first
	},
}
