local utils = require("code_morpher.morpher.utils")


return function(action_description, prompt_key)
  return {
    get_context_node = function(_, ts_start)
      local node = utils.findup(ts_start, "function_definition")
      return {
        action_name = action_description,
        available = node ~= nil
      }
    end,
    generator = function(_, text)
      -- TODO(patwie): find another way.
      local script_path = "git/github.com/patwie/code-morpher.nvim/python/claude.py"
      local llm_output = vim.fn.system(
        "python3 " .. vim.fn.expand('$HOME/') .. script_path .. " " .. prompt_key,
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
      local replacement_text = self:generator(function_text)
      ctx:replace_text(func_node, replacement_text, true)
    end
  }
end
