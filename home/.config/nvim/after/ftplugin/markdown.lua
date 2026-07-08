-- Neovim 0.12 starts Treesitter automatically for Markdown, but the bundled
-- Markdown highlighter currently crashes with the installed parser/query set.
-- Keep Treesitter for code buffers and use the stable regex syntax for Markdown.
pcall(vim.treesitter.stop, 0)

for _, lhs in ipairs({ "gO", "]]", "[[" }) do
	pcall(vim.keymap.del, "n", lhs, { buffer = 0 })
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. "\n lua pcall(vim.treesitter.stop, 0)"
