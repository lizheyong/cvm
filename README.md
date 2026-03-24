# ✦ CVM — Claude Version Manager

Manage multiple [Claude Code](https://docs.anthropic.com/en/docs/claude-code) versions side-by-side. Switch per-terminal, like conda.

```
❯ cvm list
✦ Claude Code Versions

  ▸ 2.1.77  system  ● active
    2.3.0   cvm
    2.2.5   cvm
```

## Features

- **Per-terminal switching** — different terminals can run different versions simultaneously
- **System version detection** — auto-detects your globally installed Claude Code
- **Zero-overhead prompt** — exports `$CVM_VERSION` for shell prompt integration (no subprocess)
- **Simple** — one shell function, no daemon, no background process

## Install

```bash
npm install -g claude-cvm
```

Then restart your terminal, or:

```bash
source ~/.claude-versions/cvm.sh
```

### Manual install

```bash
curl -o ~/.claude-versions/cvm.sh https://raw.githubusercontent.com/zheyong/cvm/main/cvm.sh
mkdir -p ~/.claude-versions
echo '[[ -s "$HOME/.claude-versions/cvm.sh" ]] && source "$HOME/.claude-versions/cvm.sh"' >> ~/.zshrc
```

## Usage

```bash
# Install versions
cvm install 2.1.77
cvm install latest

# Activate in current terminal
cvm activate 2.1.77

# Open another terminal, use a different version
cvm activate latest

# Check status
cvm current
cvm list

# Deactivate (back to system claude)
cvm deactivate

# After upgrading system claude via npm
cvm refresh
```

## How it works

CVM installs each version to `~/.claude-versions/<version>/` via npm, then `cvm activate` prepends that version's bin directory to the current shell's `$PATH`. Since each terminal has its own `$PATH`, different terminals can use different versions — just like `conda activate`.

```
~/.claude-versions/
├── cvm.sh              # the shell function (sourced in .zshrc)
├── 2.1.77/             # installed via: cvm install 2.1.77
│   └── node_modules/
│       └── .bin/claude
├── 2.3.0/
│   └── node_modules/
│       └── .bin/claude
└── .sys_version        # cached system version (for fast prompt)
```

## Prompt integration (optional)

CVM exports `$CVM_VERSION` with the active version. You can display it in your prompt.

### Starship

Add to `~/.config/starship.toml`:

```toml
[env_var.CVM_VERSION]
symbol = "✦ "
style = "bold #E8976C"
format = "via [$symbol$env_value]($style) "
```

Result: `~/project on main ✦ 2.1.77`

### Oh My Zsh / vanilla zsh

Add to your `.zshrc`:

```bash
PROMPT='${CVM_VERSION:+✦ $CVM_VERSION }'"$PROMPT"
```

### Powerlevel10k

In `~/.p10k.zsh`, add a custom segment:

```bash
function prompt_cvm() {
  [[ -n "$CVM_VERSION" ]] && p10k segment -f 209 -t "✦ $CVM_VERSION"
}
# Then add 'cvm' to POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS
```

## Compatibility

- **Shell**: zsh, bash
- **OS**: macOS, Linux
- **Requires**: Node.js, npm
- **Works with**: [CC Switch](https://github.com/nicekid1/cc-switch) — CVM manages CLI binary versions, CC Switch manages providers/API keys. They don't conflict.

## Uninstall

```bash
npm uninstall -g claude-cvm
# Optionally remove installed versions:
rm -rf ~/.claude-versions
```

## License

MIT
