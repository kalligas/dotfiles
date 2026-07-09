local keymap = vim.keymap.set

keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
keymap("i", "<Esc>", "<Esc><cmd>silent write<CR>", { desc = "Exit insert mode and save" })
keymap("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
keymap("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
keymap("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find help" })
keymap("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Plugin manager" })
