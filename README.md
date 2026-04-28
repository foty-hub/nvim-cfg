# Neovim and tmux config

Personal Neovim and tmux configuration.

## Install

```sh
git clone https://github.com/foty-hub/nvim-cfg.git ~/.config/nvim
nvim
```

`init.lua` bootstraps `lazy.nvim` on first launch. Some language tooling is expected to be available on `PATH`, or through `uv run nvim` for project-local Python tooling.

## tmux

Track tmux through this repo by symlinking the real config path:

```sh
ln -s ~/.config/nvim/tmux.conf ~/.tmux.conf
```
