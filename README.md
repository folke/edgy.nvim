# 🪟 edgy.nvim

A Neovim plugin to easily create and manage predefined window layouts,
bringing a new edge to your workflow.

![image](https://github.com/folke/edgy.nvim/assets/292349/35e2b30c-4099-4f37-8830-48584529bfd5)

## ✨ Features

- 🔄 Automatically move windows (including floating windows) in a pre-defined layout
- 📐 Manage layouts while keeping your main editor splits untouched.
- 🔧 Personalize **edgebar** window options to fit your style.
- 📌 Pinned views are always shown in the sidebar even when they have no windows.
- ⌨️ Make navigation easier with personalized buffer-local _keymaps_ for **edgebar** windows.
- 🎆 Pretty animations (works well with [mini.animate](https://github.com/echasnovski/mini.animate))
- 🧩 Works with any plugin. Check [Show and Tell](https://github.com/folke/edgy.nvim/discussions/categories/show-and-tell)
  for snippets to integrate even better
  with plugins like [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim),
  [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)

## 📦 Installation

Install the plugin with your preferred package manager:

```lua
{
  "folke/edgy.nvim",
  event = "VeryLazy",
  opts = {}
}
```

## ⚙️ Configuration

**edgy.nvim** comes with the following defaults:

```lua
{
  left = {}, ---@type (Edgy.View.Opts|string)[]
  bottom = {}, ---@type (Edgy.View.Opts|string)[]
  right = {}, ---@type (Edgy.View.Opts|string)[]
  top = {}, ---@type (Edgy.View.Opts|string)[]

  ---@type table<Edgy.Pos, {size:integer, wo?:vim.wo}>
  options = {
    left = { size = 30 },
    bottom = { size = 10 },
    right = { size = 30 },
    top = { size = 10 },
  },
  -- edgebar animations
  animate = {
    enabled = true,
    fps = 100, -- frames per second
    cps = 120, -- cells per second
    on_begin = function()
      vim.g.minianimate_disable = true
    end,
    on_end = function()
      vim.g.minianimate_disable = false
    end,
    -- Spinner for pinned views that are loading.
    -- if you have noice.nvim installed, you can use any spinner from it, like:
    -- spinner = require("noice.util.spinners").spinners.circleFull,
    spinner = {
      frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      interval = 80,
    },
  },
  -- global window options for sidebar windows
  ---@type vim.wo
  wo = {
    -- Setting to `true`, will add an edgy winbar.
    -- Setting to `false`, won't set any winbar.
    -- Setting to a string, will set the winbar to that string.
    winbar = true,
    winfixwidth = true,
    winfixheight = false,
    winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
    spell = false,
    signcolumn = "no",
  },
  -- buffer-local keymaps to be added to sidebar buffers.
  -- Existing buffer-local keymaps will never be overridden.
  -- Set to false to disable a builtin.
  ---@type table<string, fun(win:Edgy.Window)|false>
  keys = {
    ["q"] = function(win)
      win:close()
    end,
    ["<c-q>"] = function(win)
      win:hide()
    end,
    ["Q"] = function(win)
      win.view.sidebar:close()
    end,
  },
  icons = {
    closed = " ",
    open = " ",
  },
  -- enable this on Neovim <= 0.10.0 to properly fold sidebar windows.
  -- Not needed on a nightly build >= June 5, 2023.
  fix_win_height = vim.fn.has("nvim-0.10.0") == 0,
}
```

### 👁️ `Edgy.View.Opts`

| **Property** | **Type**                       | **Description**                                                                                             |
| ------------ | ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| **ft**       | `string`                       | File type of the view                                                                                       |
| **filter**   | `fun(buf:buffer, win:window)?` | Optional function to filter buffers and windows                                                             |
| **title**    | `string?`                      | Optional title of the view. Defaults to the capitalized filetype                                            |
| **size**     | `number`                       | Size of the short edge of the edgebar. For sidebars, this is the minimum width. For panels, minimum height. |
| **pinned**   | `boolean?`                     | If true, the view will always be shown in the sidebar even when it has no windows                           |
| **open**     | `fun()` or `string`            | Function or command to open a pinned view                                                                   |
| **wo**       | `vim.wo?`                      | View-specific window options                                                                                |

## 🚀 Usage

Just open windows/buffers as you normally do, but now they will be displayed
in your layout.

### ⌨️ Keymaps for Edgebar Windows

| **Keymap** | **Description**   |
| ---------- | ----------------- |
| `q`        | Close the window  |
| `<c-q>`    | Hide the window   |
| `Q`        | Close the sidebar |

### 🔌 API

- `require("edgy").close(pos?)` close all sidebars or a sidebar in the given position

## 🪟 Example Setup

```lua
{
  "folke/edgy.nvim",
  event = "VeryLazy",
  opts = {
    bottom = {
      -- toggleterm / lazyterm at the bottom with a height of 40% of the screen
      { ft = "toggleterm", size = { height = 0.4 } },
      {
        ft = "lazyterm",
        title = "LazyTerm",
        size = { height = 0.4 },
        filter = function(buf)
          return not vim.b[buf].lazyterm_cmd
        end,
      },
      "Trouble",
      { ft = "qf", title = "QuickFix" },
      { ft = "help", size = { height = 20 } },
      { ft = "spectre_panel", size = { height = 0.4 } },
    },
    left = {
      -- Neo-tree filesystem always takes half the screen height
      {
        title = "Neo-Tree",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "filesystem"
        end,
        size = { height = 0.5 },
      },
      {
        title = "Neo-Tree Git",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "git_status"
        end,
        pinned = true,
        open = "Neotree position=right git_status",
      },
      {
        title = "Neo-Tree Buffers",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "buffers"
        end,
        pinned = true,
        open = "Neotree position=top buffers",
      },
      {
        ft = "Outline",
        pinned = true,
        open = "SymbolsOutline",
      },
      -- any other neo-tree windows
      "neo-tree",
    },
  },
}
```

## 🐯 Tips & tricks

- disable edgy for a window/buffer by setting `vim.b[buf].edgy_disable`
  or `vim.w[win].edgy_disable`. You can even set this after the facts.
  Edgy will then expunge the window from the layout.

- check the [Show and Tell](https://github.com/folke/edgy.nvim/discussions/categories/show-and-tell)
  section of the github discussions for snippets for better integration
  with plugins like [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim),
  [bufferline.nvim](https://github.com/akinsho/bufferline.nvim), ...
