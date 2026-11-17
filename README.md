# MeNsaaH's dotfiles

A collection of my dotfiles and system setups on Ubuntu and MacOS as Ansible Roles

prerequisites
-------------

- Ensure Python 3 is installed

- ansible
```
 pip3 install ansible
```

- Install ansible requirements 
```
ansible-galaxy install -r requirements.yml
```

- Generate SSH Key and GPG Key and add to Github account

- Run playbook
```
ansible-playbook main.yml -i inventory --ask-become-pass
```

Secrets
-------

`secrets` caches secret values in the login keychain, encrypted by the Secure
Enclave. The reference you pass picks the source: the 1Password CLI, the
LastPass CLI, an existing keychain item, or a shell command. macOS only, since
the encryption key lives in the Secure Enclave. Commands and reference schemes
are documented in `files/dotfiles/generic/.config/secrets/README.md`.

Build it once per Mac:

```bash
swiftc -O -o ~/.local/bin/secrets ~/.config/secrets/secrets.swift
codesign --force --sign - ~/.local/bin/secrets
```

`~/.config/direnv/direnvrc` defines `from_secrets VAR [ref|field]`, which
exports a variable from that cache:

```bash
# .envrc
export SECRETS_DEFAULT_REF="op://Employee/CLI tokens"   # or lpass://Shared/GitHub

from_secrets GITLAB_TOKEN gitlab-pat-zdev        # op://Employee/CLI tokens/gitlab-pat-zdev
from_secrets PAGERDUTY_API_TOKEN "keychain://PagerDuty/user"
from_secrets BUILD_TOKEN "cmd://pass show build/token"
```

An argument that contains `://` is used as the whole reference. Otherwise the
name appends to `SECRETS_DEFAULT_REF`. Set that variable in a machine-local
file such as `~/.config/zsh/work.zsh`, which `.zshrc` sources when present.

`direnv` does not load on `cd` in this setup. Run `direnv-load` in the
directory that needs the variables, and the shell hook unloads them when you
leave it. That keeps keychain and Touch ID prompts off directory changes.

A failed or empty read leaves the variable unset and prints the reason, so a
missing secret cannot become an empty credential.

Coding agents
-------------

No agent config is tracked as a file. Everything under `templates/agents/` is
rendered into the home directory, because these files carry paths, model names
and endpoints that differ per machine:

| Template | Deployed to |
|---|---|
| `claude-CLAUDE.md.j2` | `~/.claude/CLAUDE.md` |
| `claude-settings.json.j2` | `~/.claude/settings.json` |
| `codex-AGENTS.md.j2` | `~/.codex/AGENTS.md` |
| `codex-config.toml.j2` | `~/.codex/config.toml` |
| `codex-hooks.json.j2` | `~/.codex/hooks.json` |
| `omp-config.yml.j2` | `~/.omp/agent/config.yml` |
| `omp-models.yml.j2` | `~/.omp/agent/models.yml` |
| `omp-mcp.json.j2` | `~/.omp/agent/mcp.json` |
| `hindsight-claude-code.json.j2` | `~/.hindsight/claude-code.json` |
| `hindsight-coding-agent.json.j2` | `~/.hindsight/coding-agent.json` |
| `hindsight.env.j2` | `~/.hindsight/hindsight.env`, written only when missing |

Values live under `agent_config` in `default-config.yml`. The tracked defaults
are generic: no employer name, no model ids, no endpoint. Put real values in
`system-specific-config.yml` at the repo root, which git ignores:

```yaml
agent_config:
  about: "SRE at <company>."
  work_dir: "{{ ansible_env.HOME }}/work"
  models:
    claude: "claude-sonnet-5"
    codex: "gpt-5.4"
    omp_default: "openai/gpt-5.4"
  codex_provider:
    name: "gateway"
    base_url: "https://gateway.example.com/v1"
    api_key_env: "AI_GATEWAY_API_KEY"
  mcp_servers:
    - {name: docs, url: "https://docs.example.com/mcp"}
    - {name: memory, command: node, args: ["{{ ansible_env.HOME }}/.local/memory/server.js"]}
  claude_marketplaces: ["owner/marketplace"]
  claude_plugins: ["plannotator@plannotator"]
```

An empty `base_url` leaves the provider blocks out, so the tools fall back to
their own defaults. An empty `models.codex` leaves the Codex model line out.

MCP servers and plugins go through each tool's CLI (`claude mcp add`,
`codex mcp add`, `claude plugin install`, `codex plugin add`) instead of being
written into the config files, so the tool records them in its own store. The
playbook skips a server or plugin that already exists.

Run the step on its own:

```bash
ansible-playbook main.yml -i inventory --ask-become-pass --tags agents
```

Everything that authenticates or records work stays out of this repo:
`~/.codex/auth.json`, `~/.claude/.env`, `~/.claude.json`, the model key in
`~/.hindsight/hindsight.env`, the sqlite histories under `~/.omp/agent` and
`~/.codex`, and the installed Hindsight plugin under `~/.hindsight/coding-agents/`.

omp comes from `homebrew_installed_packages`. The Hindsight coding-agent plugin
stages itself into `~/.hindsight/coding-agents/` from the
`@vectorize-io/hindsight-coding-agents` npm package, and the hook entries in
`codex-hooks.json.j2` point at that directory.

Todo
----
- [ ] Ubuntu: Auto Setup Theme (Gnome-tweaks, dash to panel extensions)
- [ ] Ubuntu: Gogh for theme selection

