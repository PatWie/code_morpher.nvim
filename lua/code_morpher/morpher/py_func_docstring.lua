local utils = require("code_morpher.morpher.utils")


return {
  get_context_node = function(_, ts_start)
    local node = utils.findup(ts_start, "function_definition")
    return {
      action_name = "Enhance function docstring",
      available = node ~= nil
    }
  end,
  generator = function(_, text)
    -- TODO(patwie): find another way.
    local script_path = "git/github.com/patwie/code-morpher.nvim/python/claude.py"
    local llm_output = vim.fn.system(
      "python3 " .. vim.fn.expand('$HOME/') .. script_path .. " enhance_func_docstring",
      text)
    llm_output = utils.strip_trailing_newline(llm_output)
    return llm_output
  end,

  run = function(self, ts_start, ctx)
    local func_node = utils.findup(ts_start, "function_definition")
    if func_node == nil then
      return
    end

    local docstring_query = vim.treesitter.query.parse("python", [[
  (function_definition
    body: (block
      (expression_statement
        (string) @docstring)))
]])
    local body_query = vim.treesitter.query.parse("python", [[
      (function_definition
    body: (block) @body)
      ]])
    local docstring_node = utils.first_capture_group_by_name(func_node, docstring_query, "docstring")
    -- ctx:i(dst)
    local function_text = ctx:get_text(func_node)
    local replacement_text = self:generator(function_text)
    if docstring_node ~= nil then
      ctx:replace_text(docstring_node, replacement_text, true)
    else
      local body_node = utils.first_capture_group_by_name(func_node, body_query, "body")
      ctx:prepend_text(body_node, replacement_text, true)
    end
  end
}
