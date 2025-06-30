local core = require("codemorpher.core")
local config = require("codemorpher.config").options

local M = {}

M.name = "Add Comment (Visual)"

-- Simple mapping of filetype to comment string
local comment_strings = {
  lua = "--",
  python = "#",
  javascript = "//",
  typescript = "//",
  rust = "//",
  go = "//",
  c = "//",
  cpp = "//",
}

---@param ctx CodeMorpher.Context
function M.is_available(ctx)
  return ctx.visual_selection ~= nil
end

---@param ctx CodeMorpher.Context
function M.run(ctx)
  local selection = ctx.visual_selection
  if not selection then
    return
  end

  local prompt = string.format(config.prompts.add_comment, selection.text)
  -- vim.notify(prompt, vim.log.levels.INFO)

  core.run_llm_job(prompt, function(lines)
    local comment_prefix = (comment_strings[ctx.filetype] or "#") .. " "
    local formatted_comment = {}
    comment_prefix = ""
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(formatted_comment, comment_prefix .. line)
      end
    end

    local indent = vim.fn.indent(selection.start_line + 1)
    local indented_comment = {}
    for _, line in ipairs(formatted_comment) do
      table.insert(indented_comment, string.rep(" ", indent) .. line)
    end

    vim.api.nvim_buf_set_lines(ctx.bufnr, selection.start_line, selection.start_line, false, indented_comment)
  end)
end

return M
