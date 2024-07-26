# CodeMorpher

A context-aware code generator. Think of LSP but with an LLM backend.

```lua
:lua require("code_morpher").pick_action()
```

will list all possible actions for the current context.

## Custom Morpher

Each morhper implements the following interface

```lua

return {
  get_context_node = function(_, ts_start)
    return {
      action_name = "<Name of action>",
      available = true|false
    }
  end,
  run = function(self, ts_start, ctx)
    ctx:replace_text(some_node, "new-text", false)
  end
}
```
