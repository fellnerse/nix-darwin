local wezterm = require("wezterm")
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "nord"
config.debug_key_events = true
config.font_size = 12.0

-- fixing the problem with the left key pressing
-- https://github.com/wez/wezterm/issues/5468
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false

config.font = wezterm.font("MonaspiceNe Nerd Font Mono")
-- Problem with finding of path

wezterm.action.SpawnCommandInNewWindow({
        args = { "nvim", wezterm.config_file },
})

function tab_title(tab_info)
        local title = tab_info.tab_title
        -- if the tab title is explicitly set, take that
        if title and #title > 0 then
                return title
        end
        -- Otherwise, use the title from the active pane
        -- in that tab
        return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
        local title = tab_title(tab)
        if tab.is_active then
                return {
                        { Background = { Color = "green" } },
                        { Text = " " .. title .. " " },
                }
        end
        return title
end)

wezterm.on("gui-startup", function(cmd)
        local tab, pane, window = mux.spawn_window(cmd or {})
        window:gui_window():maximize()
end)

config.keys = {
        -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
        { key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
        -- Make Option-Right equivalent to Alt-f; forward-word
        { key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
}

config.keys = {
        -- This will create a new split and run your default program inside it
        {
                key = "-",
                mods = "ALT",
                action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
        },
}
config.keys = {
        -- This will create a new split and run your default program inside it
        {
                key = "+",
                mods = "ALT",
                action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
        },
}

-- add nix profile path to PATH; wezterm is started via finder, which has very minimal PATH
-- https://github.com/wezterm/wezterm/issues/3950#issuecomment-1667922224
-- config.set_environment_variables = {
--     PATH = wezterm.home_dir .. '/.nix-profile/bin:' .. os.getenv('PATH')
-- }
-- config.default_prog = { 'zellij', '-l', 'welcome' }

-- load wuake style module
require("wuake").setup {
  config = config,
}

-- and finally, return the configuration to wezterm
return config