-- lua/codemorpher/config.lua
local M = {}

M.options = {
  -- The command to run your LLM. It should accept a prompt from stdin
  -- and print the result to stdout.
  -- Example: "q chat --no-interactive"
  -- Example: "ollama run codellama:7b"
  llm_command = "q chat --no-interactive",

  -- Telescope theme for the pickers
  picker_opts = require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
  }),
}

return M
