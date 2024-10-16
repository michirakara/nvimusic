# Dependencies
- mpv

# Environment
- UNIX/Linux

# Available commands
- Nvimusic
    - Show tui of playlist
- NvimusicAdd
    - Add a directory or file to the end of the playlist
- NvimusicDelete
    - Delete music from playlist
- NvimusicDeleteAll
    - Clear the playlist
- NvimusicShuffle
    - Shuffle the playlist
- NvimusicPlay
    - Start playing
    - Start at n-th element of playlist if an argument is specified
- NvimusicStop
    - Stop playing
    - Slow (because it's using SIGSTOP)
- NvimusicSkip
    - Skip to the next music
- NvimusicToggle
    - Play if stopped, stop if playing

# Shortcut in TUI
- q: quit
- r: shuffle
- s: skip
- d: delete music from playlist at cursor
- D: clear the playlist
- Space: start/stop
- CR: play music at cursor

# TODO
- [ ] config
- [ ] support more commands to play other than paplay
- [ ] make NvimusicStop faster

# Connect to lualine.nvim
Example lualine config
```lua
local function get_formatted_time()
    local sec = require("nvimusic").get_time_seconds()
    return string.format("%02d", sec / 60) .. ":" .. string.format("%02d", sec % 60)
end
local function get_title()
    local tmp = require("nvimusic").get_now_playing()
    tmp = tmp:gsub("%.mp3", "")
    if vim.fn.strdisplaywidth(tmp) > 20 then
        for i = 1, #tmp, 1 do
            if vim.str_utf_end(tmp, i) ~= 0 then
                goto continue
            end
            if vim.fn.strdisplaywidth(string.sub(tmp, 1, i)) >= 18 then
                return string.sub(tmp, 1, i) .. "…"
            end
            ::continue::
        end
    else
        return tmp
    end
end
return {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    -- event = { "BufReadPre", "BufNewFile" },
    config = function()
        require('lualine').setup({
            options = {
                path = 1,
                globalstatus = true,
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { 'filename' },
                lualine_x = { 'encoding', 'fileformat', 'filetype' },
                lualine_y = { get_formatted_time, get_title },
                lualine_z = { 'location' }
            }
        })
    end
}
```
