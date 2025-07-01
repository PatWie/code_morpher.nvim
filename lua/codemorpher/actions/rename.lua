-- lua/codemorpher/actions/rename.lua
local core = require("codemorpher.core")
local config = require("codemorpher.config").options

-- Helper to find the relevant surrounding node for context
local function find_meaningful_context_node(start_node)
  local context_types = {
    "function_definition",
    "method_definition",
    "class_definition",
    "struct_declaration",
    "interface_declaration"
  }

  for _, node_type in ipairs(context_types) do
    local context_node = core.find_ancestor(start_node, node_type)
    if context_node then
      return context_node
    end
  end

  return nil
end


PROMPT_TEMPLATES = {
  rename_shorter = [[
Given the following code context, suggest exactly 10 shorter, alternative names for the variable or function `%s`.
The names should be valid for the language and maintain clarity.
Output each suggestion on a new line, with no other text.
Respect the language which might be python, c++, typescript or golang and use language idiomatic naming style!

Context: %s ]],
  rename_concise = [[
Given the following code context, suggest exactly 10 more descriptive and concise names for the variable or function `%s`.
The names should be idiomatic for the language.
Output each suggestion on a new line, with no other text.

<instructions>
1. You will be provided with a code context and a target variable or function marked in <context>.
2. Analyze the code context and understand the purpose and usage of <variable>.
3. Refer to the <template> and <examples> tags for guidance on tone and structure. The <examples> include <example_context> and <example_output> pairs for reference only — do not copy or reuse their content.
4. Based on this analysis, suggest **exactly 10 alternative names** that are:
  - More descriptive and concise
  - Idiomatic to the language in use
  - Clearly reflect the intent and behavior of <variable>
5. Output each suggested name on a **new line**, with **no additional commentary or formatting**.
6. Do **not** include the original name <variable> in the output.
7. Focus solely on improving semantic clarity while keeping names succinct and practical for developers.
</instructions>

Example

<example>
<example_context>
#include <vector>
#include <string>

class UserManager {
public:
    void loadUsersFromFile(const std::string& filename) {
        std::ifstream infile(filename);
        std::string line;
        while (std::getline(infile, line)) {
            if (!line.empty()) {
                data.push_back(line);
            }
        }
    }

    void printUsers() const {
        for (const auto& user : data) {
            std::cout << user << std::endl;
        }
    }

private:
    std::vector<std::string> data;
};
</example_context>

<example_output>
user_list
usernames
users
loaded_users
user_records
parsed_users
user_entries
file_users
registered_users
user_strings
user_data
raw_users
username_list
user_collection
user_lines
read_users
input_users
user_buffer
user_cache
line_buffer
</example_output>

<example>

The above examples under the <examples> tags have been provided to you to illustrate general variable names.
IMPORTANT: the context & output changes provided within the examples XML tags should not be assumed to have been provided to you to use.
All of the values and information within the <examples> tag (the <example_context>, <example_output>) are strictly part of the examples and have not been provided to you.
Respect the language which might be python, c++, typescript or golang and use language idiomatic naming style!

here is your context:

<context>%s</context>

ONLY OUTPUT the <output>. NOTHING ELSE!
]]
}

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
    local cursor_node = ctx.cursor_node
    if not cursor_node then
      return
    end

    local variable_name = core.get_node_text(cursor_node, ctx.bufnr)
    local context_text
    local context_lines = 50 -- Lines for both max context and fallback window

    -- Try to find meaningful context (function, class, etc.)
    local meaningful_context_node = find_meaningful_context_node(cursor_node)

    if meaningful_context_node then
      local full_context_text = core.get_node_text(meaningful_context_node, ctx.bufnr)
      local context_line_count = select(2, full_context_text:gsub('\n', '\n')) + 1

      -- If context is reasonable size, use the full meaningful context
      if context_line_count <= context_lines then
        context_text = full_context_text
      else
        -- Fallback: limited window around the cursor node (where the variable is)
        context_text = core.get_limited_context_around_node(cursor_node, ctx.bufnr, context_lines)
      end
    else
      -- No meaningful context found, use limited window around cursor node
      context_text = core.get_limited_context_around_node(cursor_node, ctx.bufnr, context_lines)
    end

    local prompt = string.format(PROMPT_TEMPLATES[prompt_key], variable_name, context_text)

    core.run_llm_job(prompt, function(lines)
      vim.notify(vim.inspect(lines), vim.log.levels.INFO, { title = "CodeMorpher" })
      core.show_picker(lines, function(selection)
        vim.lsp.buf.rename(selection)
      end)
    end)
  end

  return action
end

return {
  create_rename_action("Improve Name", "rename_concise"),
  create_rename_action("Shorten Name", "rename_shorter"),
}
