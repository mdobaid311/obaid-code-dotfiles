-- lazy.nvim configuration for onedark theme
return {
	-- Add the onedark theme plugin
	{
		"navarasu/onedark.nvim",
		config = function()
			-- Configure the theme
			require("onedark").setup({
				style = "dark", -- Choose between "dark", "darker", "cool", "deep", "warm", "warmer", "light"
				transparent = false, -- Show a transparent background
				term_colors = true, -- Set terminal colors
				ending_tildes = false, -- Show tildes at the end of buffers
				cmp_itemkind_reverse = false, -- Reverse item kind highlights in completion menu

				-- Toggle theme styles
				code_style = {
					comments = "italic", -- Set comments to italic
					keywords = "bold", -- Set keywords to bold
					functions = "italic,bold", -- Set functions to italic and bold
					strings = "none", -- No special style for strings
					variables = "none", -- No special style for variables
				},

				-- Plugins Config
				diagnostics = {
					darker = true, -- Darker colors for diagnostics
					undercurl = true, -- Use undercurl instead of underline
					background = true, -- Use background color for virtual text
				},
			})

			-- Apply the theme
			require("onedark").load()
		end,
	},
}
