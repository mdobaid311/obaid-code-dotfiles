if vim.loader then
	vim.loader.enable()
end

_G.dd = function(...)
	require("util.debug").dump(...)
end
vim.print = _G.dd

require("config.lazy")
require("nvim-treesitter.install").compilers = { "zig", "cc", "gcc", "clang" }
-- Set Neovim to use PowerShell as the default shell
vim.opt.shell = "pwsh" -- Use "powershell" if you are using the older version
vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""

