local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("code_morpher.morpher.utils")

local Context = {
  winnr        = nil,
  bufnr        = nil,
  create       = function(self)
    self.winnr = vim.api.nvim_get_current_win()
    self.bufnr = vim.api.nvim_win_get_buf(self.winnr)
    return self
  end,
  i            = function(self, node)
    print(node:type(), vim.treesitter.get_node_text(node, self.bufnr))
  end,

  cursor_node  = function(self)
    return ts_utils.get_node_at_cursor(self.winnr)
  end,

  prepend_text = function(self, node, text, keep_indent)
    local start_row, start_col, end_row, end_col = node:range()
    if keep_indent then
      text = utils.indent_text(text, start_col)
    end
    text = text .. "\n"
    vim.api.nvim_buf_set_text(self.bufnr, start_row, 0, start_row, 0, vim.split(text, "\n"))
  end,

  -- append_text  = function(self, node, text)
  --   local start_row, start_col, end_row, end_col = node:range()
  --   vim.api.nvim_buf_set_text(self.bufnr, end_row, 0, end_row, 0, vim.split(text, "\n"))
  -- end,

  replace_text = function(self, node, text, keep_indent)
    local start_row, start_col, end_row, end_col = node:range()
    if keep_indent then
      text = utils.indent_text(text, start_col)
      start_col = 0
    end
    vim.api.nvim_buf_set_text(self.bufnr, start_row, start_col, end_row, end_col, vim.split(text, "\n"))
  end,
  get_text     = function(self, node)
    return vim.treesitter.get_node_text(node, self.bufnr)
  end

}
return Context
