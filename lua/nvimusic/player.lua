local M = {}

local uv = vim.uv
local api = vim.api

local start_time = 0
local time_resumed = 0.0

local used = false
local playlist = {}
local buf = 114514
local is_playing = false
local is_quitting = false
local playing_now = ""

local function dump_playlist()
    for key, value in pairs(playlist) do
        print(key .. ": " .. value)
    end
end

function M.add_to_playlist(path)
    local type = io.popen("file -b '" .. path .. "'"):read("*a")
    if type == "directory\n" then
        for _, fname in pairs(vim.split(io.popen("find '" .. path .. "' -type f"):read("*a"), "\n")) do
            if fname == "" then
                goto continue
            end

            table.insert(playlist, fname)

            ::continue::
        end
    else
        table.insert(playlist, path)
    end
    if buf ~= nil and api.nvim_buf_is_valid(buf) then
        local r, c = unpack(api.nvim_win_get_cursor(0))
        M.open(r, c)
    end
end

function M.delete_from_playlist(name)
    for key, value in pairs(table) do
        if value == name then
            table.remove(playlist, key)
        end
    end
end

function M.delete_all()
    playlist = {}
    if buf ~= nil and api.nvim_buf_is_valid(buf) then
        local r, c = unpack(api.nvim_win_get_cursor(0))
        M.open(r, c)
    end
end

function M.shuffle_playlist()
    for i = #playlist, 2, -1 do
        local j = math.random(i)
        playlist[i], playlist[j] = playlist[j], playlist[i]
    end
    if buf ~= nil and api.nvim_buf_is_valid(buf) then
        local r, c = unpack(api.nvim_win_get_cursor(0))
        M.open(r, c)
    end
end

local playing_index = 1

local handle, pid
local is_stopped = false

local function play_music(path)
    local tmp = vim.split(path, "/")
    playing_now = tmp[#tmp]
    start_time = os.time()
    time_resumed = 0
    handle, pid = uv.spawn("mpv", {
            args = { "--no-video", path },
        },
        vim.schedule_wrap(
            function(code)
                if is_quitting then
                    return
                end
                playing_index = playing_index + 1
                if playing_index > #playlist then
                    playing_index = 1
                end
                if code ~= 0 then
                    print(code)
                end
                if buf ~= nil and api.nvim_buf_is_valid(buf) then
                    local r, c = unpack(api.nvim_win_get_cursor(0))
                    M.open(r, c)
                end
                play_music(playlist[playing_index])
            end
        )
    )
    if handle == nil then
        print("mpv is not installed")
    end
end

function M.play_index(idx)
    if #playlist < idx then
        print("index out of bound")
        return
    end
    if not is_playing then
        M.play()
    end
    playing_index = idx - 1
    M.skip()
end

function M.play()
    if #playlist == 0 then
        print("playlist is empty")
        return
    end
    used = true
    if is_stopped then
        start_time = os.time()
        io.popen("kill -s CONT " .. pid)
    else
        play_music(playlist[playing_index])
    end
    is_playing = true
    is_stopped = false
end

function M.stop()
    if is_playing == false then
        print("music is not playing")
        return
    end
    is_playing = false
    is_stopped = true
    time_resumed = time_resumed + os.time() - start_time
    io.popen("kill -s STOP " .. pid)
end

function M.toggle()
    if is_playing then
        M.stop()
    else
        M.play()
    end
end

function M.skip()
    if is_playing == false then
        print("it is not playing")
    else
        io.popen("kill " .. pid)
    end
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

function M.open(row, column)
    print(M.get_now_playing())
    if buf ~= nil and api.nvim_buf_is_valid(buf) then
        api.nvim_buf_delete(buf, {})
    end
    buf = api.nvim_create_buf(false, true)
    vim.keymap.set('n', 'q',
        function()
            api.nvim_buf_delete(buf, {})
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', 'd',
        function()
            local r, c = unpack(api.nvim_win_get_cursor(0))
            table.remove(playlist, r)
            M.open(r, c)
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', 'D',
        function()
            M.delete_all()
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', 'r',
        function()
            M.shuffle_playlist()
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', ' ',
        function()
            M.toggle()
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', 's',
        function()
            M.skip()
        end,
        { buffer = buf }
    )
    vim.keymap.set('n', '<CR>',
        function()
            local r, _ = unpack(api.nvim_win_get_cursor(0))
            M.play_index(r)
        end,
        { buffer = buf }
    )

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
    if row ~= nil then
        api.nvim_win_set_cursor(0, { row, column })
    end
end

function M.get_time_seconds()
    if used then
        return time_resumed + os.time() - start_time
    else
        return ""
    end
end

function M.get_now_playing()
    if used then
        return playing_now
    else
        return ""
    end
end

vim.api.nvim_create_autocmd("VimLeave", {
    pattern = "*",
    callback = function()
        is_quitting = true
        if pid ~= nil then
            io.popen("kill " .. pid)
        end
        print("exiting")
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
    "NvimusicDelete",
    function(opts)
        M.delete_from_playlist(opts.args)
    end,
    {
        nargs = 1,
        complete = function(_, _, _)
            return playlist
        end
    }
)
vim.api.nvim_create_user_command(
    "NvimusicDeleteAll",
    function()
        M.delete_all()
    end,
    { nargs = 0 }
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
    function(opts)
        if #opts.fargs == 1 then
            M.play_index(tonumber(opts.args))
        else
            M.play()
        end
    end,
    { nargs = "?" }
)
vim.api.nvim_create_user_command(
    "NvimusicStop",
    function()
        M.stop()
    end,
    { nargs = 0 }
)
vim.api.nvim_create_user_command(
    "NvimusicToggle",
    function()
        M.toggle()
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
        M.open(nil, nil)
    end,
    { nargs = 0 }
)
return M
