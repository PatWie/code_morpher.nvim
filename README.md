# CodeMorpher.nvim

A Neovim plugin that integrates AI-powered code assistance directly into your
editor workflow. CodeMorpher provides context-aware actions for code
improvement, documentation, and git workflow enhancement.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "patwie/code-morpher.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codemorpher").setup({
      -- Optional configuration
    })
  end,
}
```


Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "patwie/code-morpher.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codemorpher").setup()
  end
}
```


## Configuration

```lua
require("codemorpher").setup({
  -- Command to run your LLM (default: "q chat --no-interactive")
  llm_command = "q chat --no-interactive",
  -- Alternative examples:
  -- llm_command = "ollama run codellama:7b",
  -- llm_command = "llm -m gpt-4",

  -- Telescope picker options
  picker_opts = require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
  }),
})
```


## Usage

### Basic Usage

Add a keybinding to trigger CodeMorpher actions:

```lua
vim.keymap.set("n", "<leader>q", require("codemorpher").pick_action, { desc =
"CodeMorpher actions" })
```


