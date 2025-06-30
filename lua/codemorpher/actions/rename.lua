-- lua/codemorpher/actions/rename.lua
local core = require("codemorpher.core")
local config = require("codemorpher.config").options

-- Helper to find the relevant surrounding node for context
local function get_context_node(start_node)
  local function_node = core.find_ancestor(start_node, "function_definition")
  if function_node then
    return function_node
  end
  -- Add other context types here if needed (e.g., class_definition)
  return start_node:parent() or start_node
end

-- Factory function to create rename actions
local function create_rename_action(name, prompt_key)
  local action = {}
  action.name = name

  ---@param ctx CodeMorpher.Context
  function action.is_available(ctx)
    if not ctx.cursor_node then
      return false
    end
    -- Enable for identifiers and property identifiers
    local node_type = ctx.cursor_node:type()
    return node_type == "identifier" or node_type == "property_identifier"
  end

  ---@param ctx CodeMorpher.Context
  function action.run(ctx)
    local node = ctx.cursor_node
    if not node then
      return
    end

    local var_name = core.get_node_text(node, ctx.bufnr)
    local context_node = get_context_node(node)
    local context_text = core.get_node_text(context_node, ctx.bufnr)

    local prompt = string.format(config.prompts[prompt_key], var_name, context_text)

    core.run_llm_job(prompt, function(lines)
      core.show_picker(lines, function(selection)
        vim.lsp.buf.rename(selection)
      end)
    end)
  end

  return action
end

return {
  -- create_rename_action("Suggest Shorter Name", "rename_shorter"),
  create_rename_action("Improve Name", "rename_concise"),
}
