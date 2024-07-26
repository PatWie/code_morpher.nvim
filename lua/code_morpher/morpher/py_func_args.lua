local utils = require("code_morpher.morpher.utils")

return {
  get_context_node = function(_, ts_start)
    local node = utils.findup(ts_start, "function_definition")
    return {
      action_name = "Enhance function argument annotations",
      available = node ~= nil
    }
  end,
  generator = function(_, text)
    -- TODO(patwie): find another way.
    local script_path = "git/github.com/patwie/code-morpher.nvim/python/claude.py"
    local llm_output = vim.fn.system(
      "python3 " .. vim.fn.expand('$HOME/') .. script_path .. " enhance_annotations",
      text)
    llm_output = utils.strip_trailing_newline(llm_output)
    return llm_output
  end,
  run = function(self, ts_start, ctx)
    local func_node = utils.findup(ts_start, "function_definition")
    if func_node == nil then
      return
    end
    local function_text = ctx:get_text(func_node)

    local parameter_query = vim.treesitter.query.parse("python", [[
      (function_definition
        parameters: (parameters) @parameters)
    ]])

    local parameters_node = utils.first_capture_group_by_name(func_node, parameter_query, "parameters")
    if parameters_node == nil then
      return
    end
    ctx:replace_text(parameters_node, "(" .. self:generator(function_text) .. ")", false)
  end
}
