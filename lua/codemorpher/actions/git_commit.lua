local Job = require("plenary.job")
local config = require("codemorpher.config").options

-- Factory function to create git commit actions with configurable command generation
local function create_git_commit_action(name, command_fn)
  local action = {}
  action.name = name

  ---@param ctx CodeMorpher.Context
  function action.is_available(ctx)
    return ctx.filetype == "gitcommit"
  end

  ---@param ctx CodeMorpher.Context
  function action.run(ctx)
    -- resolve COMMIT_EDITMSG next to the current file
    local commit_msg_path = vim.uv.fs_realpath(
      vim.fn.expand('%:p:h') .. "/COMMIT_EDITMSG"
    )
    if not commit_msg_path then
      vim.notify("Could not find COMMIT_EDITMSG", vim.log.levels.ERROR)
      return
    end

    -- vim.api.nvim_buf_set_lines(0, 0, -1, false, { "...thinking..." })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})

    local ns_id = vim.api.nvim_create_namespace("my_llm_stream_ns")
    local last_line = vim.api.nvim_buf_line_count(0)

    local mark_id = vim.api.nvim_buf_set_extmark(
      0,                       -- 0 means "current buffer"
      ns_id,
      last_line - 1,           -- line index is 0-based
      -1,                      -- -1 means "end of the line"
      { right_gravity = true } -- Ensures the mark stays at the end of inserted text
    )

    if mark_id == 0 then
      vim.notify("Failed to create extmark.", vim.log.levels.ERROR)
      return
    end

    -- Generate the command using the configurable function
    local formatted_command = command_fn(commit_msg_path)

    Job:new({
      command = "bash",
      args = {
        "-lc",
        formatted_command
      },
      on_stdout = function(_, data)
        -- Guard against nil or empty data chunks
        if data == nil then return end

        -- All API calls that modify the buffer must be scheduled
        vim.schedule(function()
          -- Find our extmark to get the current insertion position (row, col).
          local mark_pos = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, mark_id, {})
          if not mark_pos then
            vim.notify("Stream Error: Lost track of the insertion point extmark.", vim.log.levels.ERROR)
            return
          end
          local row, col = mark_pos[1], mark_pos[2]

          -- Group changes for a single undo history entry.
          pcall(vim.cmd.undojoin)

          -- Remove all ANSI escape codes
          local clean_data = data:gsub("\27%[[%d;]*m", "")

          -- Insert the new lines at the extmark's position.
          -- This APPENDS the text instead of replacing the whole buffer.
          vim.api.nvim_buf_set_text(0, row, col, row, col, { clean_data, "" })
        end)
      end,
      on_stderr = function(_, data)
        -- Assuming stderr data is also a raw string that needs joining if it's a table
        if data then
          vim.schedule(function()
            local msg = type(data) == "table" and table.concat(data, "\n") or data
            -- vim.notify(msg, vim.log.levels.WARN, { title = "LLM Stderr" })
          end)
        end
      end,
      on_exit = function(_, return_val)
        vim.schedule(function()
          if return_val == 0 then
            vim.notify("LLM stream finished successfully.", vim.log.levels.INFO)
          else
            vim.notify("LLM process exited with code: " .. return_val, vim.log.levels.ERROR)
          end
        end)
      end,
      enable_recording = true,
    }):start()
  end

  return action
end

-- Create different versions of the git commit action with configurable command functions
return {
  create_git_commit_action(
    "Generate Git Commit Message",
    function(commit_msg_path)
      return string.format('staged --create-prompt %s | llm-cli --stream --', commit_msg_path)
    end
  ),
  create_git_commit_action(
    "Improve Git Commit Message",
    function(commit_msg_path)
      -- Get the current buffer content (existing commit message)
      local current_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local current_message = table.concat(current_lines, "\n")

      -- Escape the current message for shell
      local escaped_message = vim.fn.shellescape(current_message)

      return string.format('echo "%s" | staged -m --create-prompt %s | llm-cli --stream --', escaped_message, commit_msg_path)
    end
  ),
}
