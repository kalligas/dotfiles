local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_macos = wezterm.target_triple:find("darwin") ~= nil
local tab_bar_bg = "rgba(22, 24, 26, 0.58)"
local tab_bg = "rgba(30, 33, 36, 0.64)"
local tab_hover_bg = "rgba(60, 64, 72, 0.76)"
local tab_active_bg = "rgba(94, 241, 255, 0.88)"

config.automatically_reload_config = true
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}

local colors = require("cyberdream")

colors.tab_bar = {
	background = tab_bar_bg,
	active_tab = {
		bg_color = tab_active_bg,
		fg_color = "#16181a",
		intensity = "Bold",
	},
	inactive_tab = {
		bg_color = tab_bg,
		fg_color = "#7b8496",
	},
	inactive_tab_hover = {
		bg_color = tab_hover_bg,
		fg_color = "#ffffff",
	},
	new_tab = {
		bg_color = tab_bar_bg,
		fg_color = "#5eff6c",
	},
	new_tab_hover = {
		bg_color = tab_hover_bg,
		fg_color = "#5eff6c",
	},
}

config.colors = colors
config.window_background_opacity = 0.80

if is_windows then
	config.win32_system_backdrop = "Acrylic"
	config.default_prog = { "wsl.exe", "-d", "Ubuntu" }
elseif is_macos then
	config.macos_window_background_blur = 30
end

config.font = wezterm.font_with_fallback({
	{ family = "JetBrains Mono", weight = "Bold" },
	"Symbols Nerd Font Mono",
	"GoMono Nerd Font Mono",
})
config.font_size = 12.5

config.keys = {
	{ key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
	{ key = "\\", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "X", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
	{ key = "h", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Right", 5 }) },
}

local function basename(path)
	if not path or path == "" then
		return "shell"
	end

	return path:gsub("(.*[/\\])(.*)", "%2")
end

wezterm.on("update-right-status", function(window, pane)
	local workspace = window:active_workspace()
	local process = basename(pane:get_foreground_process_name())
	local time = wezterm.strftime("%H:%M")

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#7b8496" } },
		{ Text = string.format(" %s  %s  %s ", workspace, process, time) },
	}))
end)

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
	local title = tab.active_pane.title
	local index = tab.tab_index + 1
	local label = string.format(" %d:%s ", index, title)

	if #label > max_width then
		label = string.format(" %d:%s ", index, wezterm.truncate_right(title, math.max(1, max_width - 5)))
	end

	local bg = tab_bg
	local fg = "#7b8496"
	local intensity = "Normal"

	if tab.is_active then
		bg = tab_active_bg
		fg = "#16181a"
		intensity = "Bold"
	elseif hover then
		bg = tab_hover_bg
		fg = "#ffffff"
	end

	return {
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Attribute = { Intensity = intensity } },
		{ Text = label },
	}
end)

return config
