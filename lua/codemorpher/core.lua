-- lua/codemorpher/core.lua
local Job = require("plenary.job")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

---@class CodeMorpher.Context
---@field winnr integer
---@field bufnr integer
---@field filetype string
---@field cursor_node table | nil
---@field visual_selection table | nil

---Creates the current context for an action.
---@return CodeMorpher.Context
function M.get_context()
  local context = {}
  context.winnr = vim.api.nvim_get_current_win()
  context.bufnr = vim.api.nvim_win_get_buf(context.winnr)
  context.filetype = vim.bo[context.bufnr].filetype
  context.cursor_node = ts_utils.get_node_at_cursor(context.winnr)

  -- Check for visual selection
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" then
    vim.cmd([[ execute "normal! \<ESC>" ]])
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    vim.cmd([[ execute "normal! gv" ]])
    local start_line = start_pos[2] - 1
    local end_line = end_pos[2] - 1
    local text = table.concat(vim.api.nvim_buf_get_lines(context.bufnr, start_line, end_line + 1, false), "\n");
    context.visual_selection = {
      start_line = start_line,
      end_line = end_line,
      text = table.concat(vim.api.nvim_buf_get_lines(context.bufnr, start_line, end_line + 1, false), "\n"),
    }
  end

  return context
end

---Finds an ancestor of a given treesitter node.
---@param start_node table The starting node.
---@param node_type string The type of ancestor to find (e.g., "function_definition").
---@return table|nil
function M.find_ancestor(start_node, node_type)
  local current_node = start_node
  while current_node do
    if current_node:type() == node_type then
      return current_node
    end
    current_node = current_node:parent()
  end
  return nil
end

---Gets the text of a given treesitter node.
---@param node table The node.
---@param bufnr integer The buffer number.
---@return string
function M.get_node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

--- Gets text from a buffer in a limited window around a given node.
--- @param node table The Treesitter node to center the context on.
--- @param bufnr integer The buffer number.
--- @param lines_around integer The number of lines to include above and below the node.
--- @return string The extracted context text.
function M.get_limited_context_around_node(node, bufnr, lines_around)
  -- Get the node's 0-indexed vertical range.
  local node_start_row, _, node_end_row, _ = node:range()

  -- Calculate the desired start and end rows for the context.
  local context_start_row = node_start_row - lines_around
  local context_end_row = node_end_row + lines_around

  -- Clamp the values to the buffer's boundaries to prevent errors.
  context_start_row = math.max(0, context_start_row)

  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  -- The end index for nvim_buf_get_lines is exclusive.
  local exclusive_end_row = math.min(total_lines, context_end_row + 1)

  -- Fetch the lines from the buffer within the clamped range.
  local lines = vim.api.nvim_buf_get_lines(bufnr, context_start_row, exclusive_end_row, false)

  return table.concat(lines, "\n")
end

---Runs the configured LLM command with a given prompt.
---@param prompt string The prompt to send to the LLM.
---@param on_result fun(result: string[]) Called with the LLM output lines when the job completes.
function M.run_llm_job(prompt, on_result)
  vim.notify("Asking AI...", vim.log.levels.INFO, { title = "CodeMorpher" })

  local config = require("codemorpher.config").options
  local output_lines = {}
  -- vim.notify(prompt, vim.log.levels.INFO, { title = "CodeMorpher" })

  -- IMPORTANT: Escape the prompt to be safely passed to a shell command.
  local escaped_prompt = vim.fn.shellescape(prompt)
  local full_command = string.format("echo %s | %s", escaped_prompt, config.llm_command)
  -- local full_command = string.format("%s %s", config.llm_command, escaped_prompt)


  Job:new({
    command = "bash",
    -- Use '-lc' to ensure the user's full shell environment is loaded,
    -- which helps find commands like 'q'.
    args = { "-lc", full_command },
    on_stdout = function(_, data)
      -- Remove all ANSI escape codes
      local clean_data = data:gsub("\27%[[%d;]*m", ""):gsub("^%s*>%s*", "")
      if clean_data then
        table.insert(output_lines, clean_data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify(data, vim.log.levels.WARN, { title = "CodeMorpher LLM Error" })
        end)
      end
    end,
    on_exit = function(_, return_val)
      vim.schedule(function()
        if return_val == 0 then
          vim.notify("AI response received.", vim.log.levels.INFO, { title = "CodeMorpher" })
          on_result(output_lines)
        else
          vim.notify("LLM process exited with code: " .. return_val, vim.log.levels.ERROR)
        end
      end)
    end,
  }):start()
end

---Shows a Telescope picker with a list of items.
---@param items string[] The items to display.
---@param on_select fun(selection: string) The callback to run when an item is selected.
function M.show_picker(items, on_select)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local config = require("codemorpher.config").options

  pickers.new(config.picker_opts, {
    prompt_title = "AI Suggestions",
    finder = finders.new_table({ results = items }),
    sorter = require("telescope.config").values.generic_sorter(config.picker_opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        on_select(selection.value)
      end)
      return true
    end,
  }):find()
end

return M
