if vim.g.loaded_nvimusic == 1 then
    return
end
vim.g.loaded_nvimusic = 1

return require("nvimusic")
