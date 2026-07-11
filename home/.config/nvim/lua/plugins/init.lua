return {
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("cyberdream").setup({
				variant = "default",
				transparent = true,
				terminal_colors = true,
				italic_comments = true,
				hide_fillchars = true,
				borderless_pickers = true,
				cache = true,
				highlights = {
					Normal = { bg = "NONE" },
					NormalNC = { bg = "NONE" },
					NormalFloat = { bg = "NONE" },
					FloatBorder = { bg = "NONE" },
					FloatTitle = { bg = "NONE" },
					Pmenu = { bg = "NONE" },
					TelescopeNormal = { bg = "NONE" },
					TelescopeBorder = { bg = "NONE" },
					TelescopePromptNormal = { bg = "NONE" },
					TelescopePromptBorder = { bg = "NONE" },
					TelescopePreviewNormal = { bg = "NONE" },
					TelescopePreviewBorder = { bg = "NONE" },
					TelescopeResultsNormal = { bg = "NONE" },
					TelescopeResultsBorder = { bg = "NONE" },
				},
			})

			vim.cmd.colorscheme("cyberdream")
		end,
	},

	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			local theme = {
				normal = {
					a = { fg = "#16181a", bg = "#5ef1ff", gui = "bold" },
					b = { fg = "#ffffff", bg = "#3c4048" },
					c = { fg = "#ffffff", bg = "NONE" },
				},
				insert = {
					a = { fg = "#16181a", bg = "#5eff6c", gui = "bold" },
					b = { fg = "#ffffff", bg = "#3c4048" },
					c = { fg = "#ffffff", bg = "NONE" },
				},
				visual = {
					a = { fg = "#16181a", bg = "#bd5eff", gui = "bold" },
					b = { fg = "#ffffff", bg = "#3c4048" },
					c = { fg = "#ffffff", bg = "NONE" },
				},
				replace = {
					a = { fg = "#16181a", bg = "#ff6e5e", gui = "bold" },
					b = { fg = "#ffffff", bg = "#3c4048" },
					c = { fg = "#ffffff", bg = "NONE" },
				},
				command = {
					a = { fg = "#16181a", bg = "#f1ff5e", gui = "bold" },
					b = { fg = "#ffffff", bg = "#3c4048" },
					c = { fg = "#ffffff", bg = "NONE" },
				},
				inactive = {
					a = { fg = "#7b8496", bg = "NONE" },
					b = { fg = "#7b8496", bg = "NONE" },
					c = { fg = "#7b8496", bg = "NONE" },
				},
			}

			require("lualine").setup({
				options = {
					theme = theme,
					globalstatus = true,
					component_separators = "",
					section_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "encoding", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},

	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = { "NvimTreeToggle", "NvimTreeFocus" },
		keys = {
			{ "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
		},
		opts = {
			view = {
				width = 34,
			},
			renderer = {
				group_empty = true,
				highlight_git = true,
				indent_markers = {
					enable = true,
				},
			},
			filters = {
				dotfiles = false,
			},
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find help" },
		},
		opts = {
			defaults = {
				border = true,
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						preview_width = 0.55,
					},
					width = 0.9,
					height = 0.85,
				},
				sorting_strategy = "ascending",
				prompt_prefix = "> ",
				selection_caret = "> ",
			},
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"css",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"rust",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			},
			highlight = {
				enable = true,
				disable = { "markdown", "markdown_inline" },
				additional_vim_regex_highlighting = { "markdown" },
			},
			indent = {
				enable = true,
				disable = { "markdown", "markdown_inline" },
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "^" },
				changedelete = { text = "~" },
				untracked = { text = "+" },
			},
		},
	},

	{
		"ThePrimeagen/vim-be-good",
		cmd = "VimBeGood",
		keys = {
			{ "<leader>gb", "<cmd>VimBeGood<CR>", desc = "VimBeGood" },
		},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			indent = { char = "|" },
			scope = { enabled = false },
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup()
			wk.add({
				{ "<leader>f", group = "find" },
				{ "<leader>g", group = "games" },
				{ "<leader>l", group = "lazy" },
			})
		end,
	},
}
