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

Todo
----
- [ ] Ubuntu: Auto Setup Theme (Gnome-tweaks, dash to panel extensions)
- [ ] Ubuntu: Gogh for theme selection

