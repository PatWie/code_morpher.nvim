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

  -- All the prompts for the various actions.
  -- `%s` will be replaced with the relevant code/context.
  prompts = {
    git_commit =
    "",

    -- rename_shorter =
    -- "Given the following code context, suggest exactly 10 shorter, alternative names for the variable or function `%s`. The names should be valid for the language and maintain clarity. Output each suggestion on a new line, with no other text.\n\nContext:\n```\n%s\n```",

    rename_concise =
    "Given the following code context, suggest exactly 10 more descriptive and concise names for the variable or function `%s`. The names should be idiomatic for the language. Output each suggestion on a new line, with no other text.\n\nContext:\n```\n%s\n```",

    add_comment =
    "Write a concise comment block explaining what the following code does. The comment should be suitable to be placed directly above the code. Do not include the code itself in your response, only the comment text.\n\nCode:\n```\n%s\n```",
  },
}

return M
