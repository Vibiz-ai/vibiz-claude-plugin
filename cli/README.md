# @vibiz/cli

Install [Vibiz for Claude Code](https://github.com/Vibiz-ai/vibiz-claude-plugin) in one command.

```bash
npx @vibiz/cli
```

That's it. The script:

1. Verifies `claude` CLI is installed
2. Runs `claude plugin marketplace add Vibiz-ai/vibiz-claude-plugin`
3. Runs `claude plugin install vibiz@vibiz`
4. Tells you to open Claude Code, run `/mcp`, pick `vibiz`, and authenticate

If anything fails, it prints the manual slash commands so you can finish the install from inside Claude Code.

## Prereqs

You need Claude Code on your machine. Install with:

```bash
brew install claude-code
# or
npm i -g @anthropic-ai/claude-code
```

…and an active [Vibiz](https://vibiz.ai) account — first authentication redirects there.

## What you're installing

The plugin gives Claude Code 5 slash commands (`/vibiz:status`, `/vibiz:onboard`, `/vibiz:post`, `/vibiz:ad`, `/vibiz:launch`), a `vibiz-marketer` subagent, and a post-commit hook that drafts marketing posts about your changes. See the [plugin README](https://github.com/Vibiz-ai/vibiz-claude-plugin) for the full surface.

## License

MIT
