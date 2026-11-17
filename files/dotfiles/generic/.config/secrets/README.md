# secrets

A TTL cache for CLI secrets. Each secret is fetched once, sealed with the Secure
Enclave, and stored as ciphertext in the login keychain. Reads inside the TTL
decrypt from the keychain and never reach the source again.

## Why it exists

Shell hooks and coding agents ask for the same tokens on every command. Reading
them from 1Password or LastPass each time costs a biometric or master-password
prompt. The usual shortcuts trade that prompt away: environment variables,
plaintext cache files, unencrypted keychain items stay readable to every process
running as you. This tool keeps the cache encrypted under a key that cannot
leave the Secure Enclave, so a process that scans your home directory or the
keychain finds ciphertext it cannot open.

## Build

Needs macOS on Apple silicon or a T2 chip, and a Swift toolchain from the Xcode
command line tools.

```bash
swiftc -O -o ~/.local/bin/secrets ~/.config/secrets/secrets.swift
codesign --force --sign - ~/.local/bin/secrets
```

Sign the binary. macOS associates keychain access with a code signature, and an
ad-hoc signature is enough for a local tool.

## Commands

| Command | Effect |
|---|---|
| `secrets read <ref> [--ttl N] [--refresh]` | Print the secret, caching it for N seconds |
| `secrets list` | Cached references, with time left or `expired` |
| `secrets clear [<ref>]` | Drop one cached entry, or all of them |
| `secrets status` | Secure Enclave availability, key file, cache size |

The default TTL is 300 seconds. `SECRETS_TTL` overrides it, `--ttl` overrides
both. On a cache hit, `--ttl` extends the lifetime without fetching, and
`--refresh` fetches from the source again. The value goes to stdout with no
trailing newline, so `$(secrets read ...)` is exact.

## References

The scheme picks the source.

| Reference | Runs |
|---|---|
| `op://vault/item/field` | `op read` |
| `lpass://Group/Item` | `lpass show --password Group/Item` |
| `lpass://Group/Item?field=username` | `lpass show --field=username Group/Item` |
| `keychain://service` | `security find-generic-password -s service -w` |
| `keychain://service/account` | `security find-generic-password -s service -a account -w` |
| `cmd://<shell command>` | `/bin/sh -c '<shell command>'` |

A reference without a scheme appends to `SECRETS_DEFAULT_REF`:

```bash
export SECRETS_DEFAULT_REF="op://Employee/CLI tokens"
secrets read gitlab-pat-zdev        # op://Employee/CLI tokens/gitlab-pat-zdev
```

```bash
export SECRETS_DEFAULT_REF="lpass://Shared/GitHub"
secrets read pat                    # lpass://Shared/GitHub/pat
```

Set that variable per machine. Keep it with the secrets it names, in the shell
config or `.envrc` for those directories, not in this repository.

## What it stores

| Location | Contents |
|---|---|
| `~/.local/state/secrets/key.dat` | Handle to the Secure Enclave key, mode 0600 in a 0700 directory |
| Keychain item, service = reference, account = `secrets` | AES-GCM ciphertext, plus a JSON record of fetch time and TTL in the item comment |

The private key stays in the Secure Enclave. `key.dat` names it, and another
machine cannot use the handle. `secrets list` reads the metadata only, so it
never decrypts anything.

## Behaviour worth knowing

A cache hit that fails to decrypt, because `key.dat` was replaced or restored
from another machine, is dropped and fetched again.

A failed or empty fetch prints the reason on stderr and exits 1. Nothing is
cached, and a caller that checks the exit status sees a failure.

There is no lock. Two shells reading the same uncached reference at the same
time both call the source.

Nothing expires entries in the background. Ciphertext from an expired entry
stays in the keychain until the next `read` or `clear`.

## Limits

macOS only. The Secure Enclave has no equivalent on Linux.

A process that can run `secrets` as you reads any cached value until its TTL
expires. The cache controls where the plaintext sits at rest; it does not
control who can ask for it. Keep TTLs short, and keep the cache list small.

The source keeps its own access control. `lpass` prompts for the master
password unless its agent is running (`LPASS_AGENT_TIMEOUT`), and the cache
sits above that prompt.
