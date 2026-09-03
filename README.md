# joewis/localrepo — Gentoo local overlay

Custom ebuilds for packages not in `::gentoo`, maintained on the Elitedesk
(Gentoo). This is a personal overlay — packages are added as needed and may
not follow every Gentoo QA nicety, but each one passes `pkgcheck scan` with
zero warnings before it's committed.

## Adding this overlay

On a Gentoo system with `eselect-repository`:

```bash
sudo eselect repository add localrepo git https://github.com/joewis/localrepo.git
sudo emerge --sync localrepo
```

Or manually via `repos.conf`:

```ini
[localrepo]
location = /var/db/repos/localrepo
sync-type = git
sync-uri = https://github.com/joewis/localrepo.git
masters = gentoo
```

Then `sudo emerge --sync` (or `emaint sync -r localrepo`).

## Packages

| Category | Package | Notes |
|---|---|---|
| `app-misc` | `fdc` | USDA Food Data Central CLI (local script) |
| `app-misc` | `goplaces` | |
| `app-misc` | `ollama` | live git (`9999`) + systemd service |
| `app-misc` | `runpodctl` | precompiled binary |
| `app-misc` | `sag` | |
| `app-misc` | `wacli` | live git (`9999`) |
| `app-misc` | `whisper-cpp` | precompiled binary |
| `app-text` | `piper-tts` | |
| `app-text` | `tex2docx` | live git (`9999`) |
| `dev-python` | `whitenoise` | |
| `dev-util` | `gogcli` | |
| `net-finance` | `moomoo-opend` | |
| `sci-libs` | `onnxruntime` | |
| `sci-listen` | `speechmos` | |
| `sci-misc` | `llama-cpp` | |
| `www-apps` | `searxng` | live git (`9999`) + systemd service |
| `acct-group` / `acct-user` | `searxng` | user/group for searxng |

## Conventions

- **Keywords:** localrepo packages use `~amd64` and are accepted on the host
  via `/etc/portage/package.accept_keywords/zz-localrepo` (version-locked
  pins, e.g. `=app-misc/fdc-1.1.5 ~amd64`).
- **Source vs binary:** Go CLI tools that ship precompiled binaries
  (`runpodctl`, `whisper-cpp`) are packaged as binaries; everything else is
  built from source.
- **Generated content is not committed:** `distfiles/`, `metadata/md5-cache/`,
  and `*.ebuild.new` (work-in-progress ebuilds) are gitignored.

## License

Ebuilds are `GPL-2` (Gentoo Authors convention). Each package's own license
is declared in its ebuild.
