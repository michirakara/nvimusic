# Dependencies
- paplay

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
