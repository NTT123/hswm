# hswm
A tiling window manager on macOS,  powered by Lua and Hammerspoon.


# Install

- You need to install Hammerspoon first. You can get it here http://www.hammerspoon.org/

- To support multi spaces. You also need to install https://github.com/asmagill/hs._asm.undocumented.spaces.git 
(may need to load module map file; `/usr/include/xpc/module.modulemap`)

- Create config directory with

  > `git clone https://github.com/NTT123/hswm.git ~/.hammerspoon`

It will clone this repository to hammerspoon config directory.

Now, start hammerspoon app. Good luck.

# Usage

### Swap two windows
Hold `Ctrl` and `left mouse` clicked to the window you want to swap, then drag the mouse to the other window which you want to swap with.

Release the mouse to take action.

### Resize windows

Hold `Ctrl` and `right mouse` clicked, then drag the mouse to resize windows.

Release the mouse to take action.

## Moving focuses between windows

Hold `Shift` +  `Up` | `Down` | `Left` | `Right` keys to move to a new focused window.

### Mirror windows

Hold `Alt` + `y` to mirror the current focused window in the y-axis.

Hold `Alt` + `x` to mirror the current focused window in the x-axis.

### Swap horizontal and vertical splittings

Hold `Alt` + `r` to swap between splitting the window horizontally and vertically.

# Screenshot

![Imgur](https://i.imgur.com/DDvKkGt.png)

# Tips

### Turn on Dock hiding

![](https://i.imgur.com/G6bibkm.png)

### Turn on menubar hiding

![](https://i.imgur.com/BknMXV0.png)

### Hide iTerm titlebar

![Imgur](https://i.imgur.com/JhoUVFP.png)

Looking for `Style` -> `No titlebar`

# How thing works

Windows are managed in a binary tree.

# Hacking

Enjoy your hacks by editing `~/.hammerspoon/init.lua` and `tree.lua`.


# Credit

This is a Lua version mini-copy of chunkwm at https://github.com/koekeishiya/chunkwm

