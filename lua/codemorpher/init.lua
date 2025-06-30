-- lua/codemorpher/init.lua
local core = require("codemorpher.core")
local config = require("codemorpher.config")

local M = {}

-- Holds all the available actions
local available_actions = {
  require("codemorpher.actions.git_commit"),
  require("codemorpher.actions.add_comment"),
}
-- Add the rename actions from the factory
for _, action in ipairs(require("codemorpher.actions.rename")) do
  table.insert(available_actions, action)
end

---Setup function to allow user configuration.
---@param user_opts table User configuration to override defaults.
function M.setup(user_opts)
  config.options = vim.tbl_deep_extend("force", config.options, user_opts or {})
end

---Picks and runs an available LLM action based on the current context.
function M.pick_action()
  local ctx = core.get_context()
  local active_actions = {}

  for _, action in ipairs(available_actions) do
    if action.is_available(ctx) then
      table.insert(active_actions, action)
    end
  end

  if #active_actions == 0 then
    vim.notify("No CodeMorpher actions available in this context.", vim.log.levels.INFO)
    return
  end

  -- if #active_actions == 1 then
  --   -- If only one action is available, run it directly
  --   active_actions[1].run(ctx)
  -- else
  -- Otherwise, show a picker
  local action_names = {}
  for _, action in ipairs(active_actions) do
    table.insert(action_names, action.name)
  end

  core.show_picker(action_names, function(selection)
    for _, action in ipairs(active_actions) do
      if action.name == selection then
        action.run(ctx)
        break
      end
    end
  end)
  -- end
end

return M
