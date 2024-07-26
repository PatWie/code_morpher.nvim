local Context = require("code_morpher.buf_ctx")
local FunctionDocString = require("code_morpher.morpher.py_func_docstring")
local ClassDocString = require("code_morpher.morpher.py_class_docstring")
local FunctionArgs = require("code_morpher.morpher.py_func_args")

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values


local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local config = {
  enabled_features = {
    FunctionDocString,
    ClassDocString,
    FunctionArgs,
  },
  picker_opts = require("telescope.themes").get_dropdown {}

}

local M = {}

M.config = config

M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.py_func_docstring = function()
  local ctx = Context:create()
  local cursor_node = ctx:cursor_node()
  FunctionDocString:run(cursor_node, ctx)
end

M.py_class_docstring = function()
  local ctx = Context:create()
  local cursor_node = ctx:cursor_node()
  ClassDocString:run(cursor_node, ctx)
end

M.pick_action = function()
  local ctx = Context:create()
  local cursor_node = ctx:cursor_node()

  local available_actions = {}
  for _, feature in pairs(M.config.enabled_features) do
    local context = feature:get_context_node(cursor_node)
    if context.available then
      table.insert(available_actions, {
        action_name = context.action_name,
        feature = feature
      })
    end
  end


  local opts = M.config.picker_opts or {}
  pickers.new(opts, {
    prompt_title = "Context-aware LLM Actions",
    finder = finders.new_table {
      results = available_actions,
      entry_maker = function(entry)
        return {
          value = entry.feature,
          display = entry.action_name,
          ordinal = entry.action_name,
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection.value))
        selection.value:run(cursor_node, ctx)
      end)
      return true
    end,
  }):find()
end

return M
