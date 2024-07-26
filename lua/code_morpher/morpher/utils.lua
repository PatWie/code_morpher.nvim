local M = {}

M.strip_trailing_newline = function(text)
  if text:sub(-1) == "\n" then
    return text:sub(1, -2)
  end
  return text
end

M.indent_text = function(text, indent)
  local lines = vim.split(text, "\n")
  for i, line in ipairs(lines) do
    lines[i] = string.rep(" ", indent) .. line
  end
  return table.concat(lines, "\n")
end


M.findup = function(node, type)
  while node do
    if node:type() == type then
      return node
    end
    node = node:parent()
  end
  return nil
end

M.first_capture_group_by_name = function(root, query, capture_name)
  for id, node, _, _ in query:iter_captures(root) do
    local name = query.captures[id]
    if name == capture_name then
      return node
    end
  end
end

return M
