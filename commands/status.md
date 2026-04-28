---
description: Check Vibiz MCP connection and list available vibizes (brands)
---

# /vibiz:status

Check whether the Vibiz MCP server is connected and authenticated, and show the list of vibizes (brands) the user can act on.

## Steps

1. Try calling the Vibiz MCP `list_vibiz` tool.
2. If it returns a list, format it as a table with `name` and `slug`. Tell the user they can pass `target: { vibiz: "<slug>" }` to any Vibiz tool to scope it to that brand.
3. If the call fails with an auth error (`Unauthorized`, `not authenticated`, or similar):
   - Tell the user to run `/mcp`, pick `vibiz`, choose **Authenticate**, and complete the browser login.
   - Then re-run `/vibiz:status`.
4. If the call fails with a 404 or "no vibizes":
   - Tell the user they don't have any vibizes yet. Suggest running `/vibiz:onboard` to create one from this repo, or visiting https://vibiz.ai to sign up.
5. Keep the response short — 5-10 lines max.

## Notes

- Do NOT proceed silently if the MCP isn't connected. Always surface the auth step clearly.
- This command is read-only. It must NEVER create, post, or spend.
