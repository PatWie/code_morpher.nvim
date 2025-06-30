local core = require("codemorpher.core")
local config = require("codemorpher.config").options

local M = {}

M.name = "Add Comment above"


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

  local prompt_template = [[
Write a concise comment block explaining what the following code does.
The comment should be suitable to be placed directly above the code.
Do not include the code itself in your response, only the comment text.

Code:
    %s
]]

  local prompt = string.format(prompt_template, selection.text)

  core.run_llm_job(prompt, function(lines)
    local formatted_comment = {}
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(formatted_comment, line)
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
