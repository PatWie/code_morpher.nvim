local utils = require("code_morpher.morpher.utils")


return {
  get_context_node = function(_, ts_start)
    local node = utils.findup(ts_start, "comment")
    return {
      action_name = "Enhance comment",
      available = node ~= nil
    }
  end,
  generator = function(_, text)
    -- TODO(patwie): find another way.
    local script_path = "git/github.com/patwie/code-morpher.nvim/python/claude.py"
    local llm_output = vim.fn.system(
      "python3 " .. vim.fn.expand('$HOME/') .. script_path .. " enhance_comment",
      text)
    llm_output = utils.strip_trailing_newline(llm_output)
    return llm_output
  end,

  run = function(self, ts_start, ctx)
    local func_node = utils.findup(ts_start, "comment")
    if func_node == nil then
      return
    end

    local function_text = ctx:get_text(func_node)
    local replacement_text = self:generator(function_text)
    ctx:replace_text(func_node, replacement_text, true)
  end
}
