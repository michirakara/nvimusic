local M = {}

local uv = vim.uv
local api = vim.api

local playlist = {}
local buf = 114514

local function dump_playlist()
    for key, value in pairs(playlist) do
        print(key .. ": " .. value)
    end
end

function M.add_to_playlist(path)
    local type = io.popen("file -b '" .. path .. "'"):read("*a")
    if type == "directory\n" then
        for _, fname in pairs(vim.split(io.popen("find '" .. path .. "'"):read("*a"), "\n")) do
            if fname == "" then
                goto continue
            end
            if io.popen("file -b '" .. fname .. "'"):read("*a") == "directory\n" then
                goto continue
            end

            table.insert(playlist, fname)

            ::continue::
        end
    else
        table.insert(playlist, path)
    end
    if buf ~= nil and api.nvim_buf_valid(buf) then
        M.open()
    end
end

function M.shuffle_playlist()
    for i = #playlist, 2, -1 do
        local j = math.random(i)
        playlist[i], playlist[j] = playlist[j], playlist[i]
    end
    if buf ~= nil and api.nvim_buf_valid(buf) then
        M.open()
    end
end

local playing_index = 1

local handle, pid
local is_stopped = false

local function play_music(path, volume_percent)
    local volume = math.floor(volume_percent / 100 * 65536)
    handle, pid = uv.spawn("paplay", {
            args = { "--volume=" .. tostring(volume), path },
        },
        function(code)
            playing_index = playing_index + 1
            if playing_index > #playlist then
                playing_index = 0
            end
            if code ~= 0 then
                print(code)
            end
            M.open()
            play_music(playlist[playing_index], 100)
        end
    )
    if handle == nil then
        print("paplay is not installed")
    end
end

function M.play()
    if is_stopped then
        io.popen("kill -s CONT " .. pid)
    else
        play_music(playlist[playing_index], 100)
    end
    is_stopped = false
end

function M.stop()
    is_stopped = true
    io.popen("kill -s STOP " .. pid)
end

function M.skip()
    io.popen("kill " .. pid)
end

local function get_float_config()
    local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
    local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))

    local row = math.ceil(vim.o.lines - height) * 0.5 - 1
    local col = math.ceil(vim.o.columns - width) * 0.5 - 1

    local float_config = {
        row = row,
        col = col,
        relative = "editor",
        style = "minimal",
        width = width,
        height = height,
        border = "single"
    }
    return float_config
end

function M.open()
    if buf ~= nil and api.nvim_buf_valid(buf) then
        api.nvim_buf_delete(buf,{})
    end
    buf = api.nvim_create_buf(false, true)
    vim.keymap.set('n', 'q',
        function()
            api.nvim_buf_delete(buf,{})
        end,
        { buffer = buf })
    api.nvim_open_win(buf, true, get_float_config())
    local lines = {}
    for key, value in pairs(playlist) do
        if key == playing_index then
            table.insert(lines, " " .. key .. "\t" .. value)
        else
            table.insert(lines, "  " .. key .. "\t" .. value)
        end
    end
    api.nvim_buf_clear_namespace(buf, -1, 0, #playlist)
    api.nvim_buf_set_lines(buf, 0, #playlist, false, lines)
end

vim.api.nvim_create_autocmd("VimLeave", {
    pattern = "*",
    callback = function()
        io.popen("kill " .. pid)
    end
})


vim.api.nvim_create_user_command(
    "NvimusicAdd",
    function(opts)
        M.add_to_playlist(opts.args)
    end,
    {
        nargs = 1,
        complete = "file",
    }
)
vim.api.nvim_create_user_command(
    "NvimusicShuffle",
    function()
        M.shuffle_playlist()
    end,
    { nargs = 0 }
)
vim.api.nvim_create_user_command(
    "NvimusicPlay",
    function()
        M.play()
    end,
    { nargs = 0 }
)
vim.api.nvim_create_user_command(
    "NvimusicStop",
    function()
        M.stop()
    end,
    { nargs = 0 }
)
vim.api.nvim_create_user_command(
    "NvimusicSkip",
    function()
        M.skip()
    end,
    { nargs = 0 }
)
vim.api.nvim_create_user_command(
    "Nvimusic",
    function()
        M.open()
    end,
    { nargs = 0 }
)
return
