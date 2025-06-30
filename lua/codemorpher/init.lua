-- lua/codemorpher/init.lua
local core = require("codemorpher.core")
local config = require("codemorpher.config")

local M = {}

local uv = vim.loop
local available_actions = {}

-- Get the absolute directory of the currently executing file
local current_file = debug.getinfo(1, "S").source:sub(2)
local actions_dir = vim.fn.fnamemodify(current_file, ":h") .. "/actions"

-- Helper to scan files in the actions directory
local function get_action_modules()
  local modules = {}
  local handle = uv.fs_scandir(actions_dir)
  if handle then
    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name then break end
      if type == "file" and name:sub(-4) == ".lua" then
        local mod_name = name:sub(1, -5) -- strip ".lua"
        table.insert(modules, "codemorpher.actions." .. mod_name)
      end
    end
  end
  return modules
end

-- Load and normalize actions
for _, module_path in ipairs(get_action_modules()) do
  local ok, actions = pcall(require, module_path)
  if ok then
    if type(actions) == "table" then
      if #actions > 0 then
        for _, action in ipairs(actions) do
          table.insert(available_actions, action)
        end
      else
        table.insert(available_actions, actions)
      end
    end
  else
    vim.notify("Failed to load module: " .. module_path, vim.log.levels.WARN)
  end
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
