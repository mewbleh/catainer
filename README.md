# catainer

`catainer` is a single-file Termux container manager for creating and running Linux distributions with `proot`.
It targets Android devices where Docker, systemd, privileged mounts, and traditional root access are usually unavailable.

No Android root is required. Rooted devices can opt in to host-root execution when they need real Android root privileges.

Current version: `1.6.3`

## Highlights

- Create Ubuntu, Debian, Alpine, Arch Linux, Fedora, Kali, openSUSE, and other rootfs-based containers.
- Choose distro releases and flavors before creating a container.
- Run rootless Linux containers under `~/.catainer` with `proot`.
- Enter a normal shell, run one-off commands, or start a distro login session with `runuser`, `su`, or `/bin/login`.
- Show distro MOTD files and clean prompts such as `root@u24:~#`.
- Manage bind mounts, environment variables, and extra `proot` arguments from the CLI.
- Create direct launchers, clone or rename containers, back up and restore containers, and upgrade packages.
- Repair missing CA bundles for `curl`, `git`, package managers, and installers.
- Use optional host-root mode on rooted Android devices through `su` or `tsu`.
- Generate Bash or Zsh completion and run CI checks with ShellCheck.

## Install

Install Termux dependencies:

```sh
pkg install -y proot tar curl ca-certificates xz-utils gzip zstd coreutils
```

Install catainer from GitHub:

```sh
curl -fsSL https://raw.githubusercontent.com/mewbleh/catainer/main/install.sh | sh
```

Or install from a local checkout:

```sh
chmod +x ./catainer
./catainer self-install
hash -r
```

Update catainer:

```sh
catainer update --check
catainer update
```

The same command upgrades container packages when you pass a container name:

```sh
catainer update u24
```

## Quick Start

Show the command overview:

```sh
catainer
catainer status
```

Create and enter Ubuntu 24.04:

```sh
catainer create u24 --distro ubuntu --release 24.04
catainer shell u24
```

Start a distro login session:

```sh
catainer login u24
catainer login u24 --method su
catainer distro-login u24
```

Run one command:

```sh
catainer exec u24 -- apt-get update
```

Create a direct launcher:

```sh
catainer link u24
u24
u24 uname -a
```

Create from a release and flavor picker:

```sh
catainer create lab --distro debian --select
```

Create common distros:

```sh
catainer create debian-slim --distro debian --release bookworm --variant slim
catainer create arch --distro archlinux
catainer create fedora --distro fedora --release 44
catainer create kali --distro kali
catainer create tumbleweed --distro opensuse --release tumbleweed
catainer create alpine --distro alpine
```

Create a default non-root user:

```sh
catainer create u24-dev --distro ubuntu --release 24.04 --user dev
catainer shell u24-dev
```

Use a custom rootfs archive:

```sh
catainer create lab \
  --distro custom \
  --url https://example.com/rootfs.tar.xz \
  --sha256 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

## Command Reference

### Setup And Discovery

```text
catainer version [--json]
catainer setup
catainer status
catainer sources
catainer releases DISTRO [--arch ARCH] [--mirror URL]
catainer flavors DISTRO [--release RELEASE] [--arch ARCH] [--mirror URL]
catainer completion bash|zsh
```

### Container Lifecycle

```text
catainer create NAME [options]
catainer ls
catainer inspect NAME
catainer update NAME
catainer clone NAME NEW_NAME [--force]
catainer rename OLD_NAME NEW_NAME
catainer delete NAME [--force]
```

### Enter And Run

```text
catainer shell NAME [--user USER] [--workdir DIR] [--host-root] [-- COMMAND...]
catainer exec NAME [--user USER] [--workdir DIR] [--host-root] -- COMMAND...
catainer login NAME [--user USER] [--workdir DIR] [--host-root] [--method auto|runuser|su|login]
catainer root-shell NAME [--user USER] [--workdir DIR] [-- COMMAND...]
catainer root-exec NAME [--user USER] [--workdir DIR] -- COMMAND...
```

### Configuration

```text
catainer link NAME [ALIAS] [--target DIR] [--force]
catainer mount NAME SOURCE:TARGET[:ro]
catainer mounts NAME
catainer mounts add NAME SOURCE:TARGET[:ro]
catainer mounts rm NAME INDEX|SPEC
catainer env NAME KEY=VALUE
catainer envs NAME
catainer envs set NAME KEY=VALUE
catainer envs rm NAME KEY
catainer args NAME
catainer args NAME ARG...
catainer args rm NAME INDEX|ARG
catainer set NAME KEY=VALUE
catainer compat NAME [show|android-safe|default]
```

### Maintenance

```text
catainer certs NAME [check|repair]
catainer doctor [NAME] [--host-root] [--run-tests]
catainer backup NAME [OUTPUT.tar.gz]
catainer restore NAME ARCHIVE.tar.gz [--force]
catainer update [--check|--refresh]
catainer update [--target PATH] [--url URL] [--force] [--dry-run]
catainer self-install [TARGET]
```

Compatibility aliases remain supported:

```text
deps=setup, distros=sources, versions=releases, variants=flavors
install=create, enter=shell, run=exec, shortcut=link
list=ls, info=inspect, proot-arg=args, config=set
self-update=update, updates=update --check, upgrade=update NAME
remove=delete, check-update=update --check
```

## Create Options

```text
-d, --distro NAME       distro name, e.g. ubuntu, fedora, archlinux, kali
-r, --release RELEASE   distro release
-a, --arch ARCH         rootfs architecture
    --url URL           custom rootfs archive URL, or built-in URL override
    --sha256 SHA256     verify a downloaded archive
    --mirror URL        override the distro mirror or base URL
    --variant VARIANT   distro flavor or variant
    --hostname NAME     hostname inside the container
-u, --user USER         create and use a default container user
-m, --mount SPEC        add a bind mount
-e, --env KEY=VALUE     add an environment variable
    --post-install FILE run a host-side script inside the container after create
    --no-default-mounts skip default Termux and Android mounts
    --select            force the release and flavor picker
    --no-select         use defaults without prompting
    --skip-deps         do not install missing Termux packages automatically
-f, --force             replace an existing local container
```

Global flags may be passed before any command:

```sh
catainer --color never
catainer --progress never create u24 --distro ubuntu
catainer --plain ls
catainer --proot-no-seccomp shell u24
catainer --proot-assume-new-seccomp shell u24
catainer --no-proot-fake-root shell u24
catainer --no-proot-link2symlink shell u24
catainer --no-update-notify
```

## Container Sessions

`catainer shell NAME` starts an interactive shell directly through `proot`.
`catainer exec NAME -- COMMAND` runs one command inside the container.
`catainer login NAME` starts a login-style session using the best available distro tool:

1. `runuser -l USER`
2. `su - USER`
3. `/bin/login -f USER`

Normal Debian and Ubuntu login banners usually depend on PAM. Catainer also displays distro MOTD files itself when PAM does not set `MOTD_SHOWN`.
If no distro MOTD exists, catainer shows its own small banner without replacing the distro's `/etc/motd`.

Catainer writes these integration files inside each rootfs:

```text
/etc/catainer-motd
/etc/profile.d/catainer.sh
/usr/local/bin/catainer-motd
/usr/local/bin/catainer-info
```

Disable the catainer prompt override:

```sh
catainer env u24 CATAINER_PROMPT=0
```

## Customization

Manage bind mounts:

```sh
catainer mount u24 /sdcard/projects:/projects
catainer mounts u24
catainer mounts rm u24 1
```

Manage environment variables:

```sh
catainer env u24 EDITOR=nano
catainer envs u24
catainer envs rm u24 EDITOR
```

Manage extra `proot` arguments:

```sh
catainer args u24 --sysvipc
catainer args u24
catainer args rm u24 1
```

Create launchers:

```sh
catainer link u24
catainer link u24 ubuntu --target "$PREFIX/bin" --force
```

Generate shell completion:

```sh
mkdir -p "$PREFIX/etc/bash_completion.d"
catainer completion bash > "$PREFIX/etc/bash_completion.d/catainer"
mkdir -p "${ZDOTDIR:-$HOME}/.zfunc"
catainer completion zsh > "${ZDOTDIR:-$HOME}/.zfunc/_catainer"
```

Control the download progress bar:

```sh
CAT_PROGRESS=always catainer create arch --distro archlinux
CAT_PROGRESS=never catainer create arch --distro archlinux
CAT_PROGRESS_WIDTH=40 catainer create arch --distro archlinux
CAT_PROGRESS_STEP=5 catainer create arch --distro archlinux
CAT_PROGRESS_MODE=bar catainer create arch --distro archlinux
```

The default progress mode prints compact milestone lines so copied logs stay readable.
Set `CAT_PROGRESS_MODE=bar` for a live single-line redraw.

## Compatibility

Proot compatibility defaults are tuned for Android kernels:

```sh
CAT_PROOT_NO_SECCOMP=always catainer shell u24
CAT_PROOT_NO_SECCOMP=never catainer shell u24
CAT_PROOT_ASSUME_NEW_SECCOMP=always catainer shell u24
CAT_PROOT_ASSUME_NEW_SECCOMP=never catainer shell u24
CAT_PROOT_UNSET_LD_PRELOAD=always catainer shell u24
CAT_PROOT_FAKE_ROOT=never catainer shell u24
CAT_PROOT_LINK2SYMLINK=never catainer shell u24
CAT_PROOT_TMP_DIR=$HOME/.catainer/tmp/proot catainer shell u24
```

On Termux, catainer sets `PROOT_NO_SECCOMP=1`, `PROOT_ASSUME_NEW_SECCOMP=1`, clears host `LD_PRELOAD`, and gives proot a private temp directory under `~/.catainer/tmp/proot` by default.
That private proot temp directory is host-side only. Commands inside the container use `TMPDIR=/tmp`, which keeps Debian package scripts and tools such as `mktemp` away from Termux host paths.

Save the stricter Android profile for one container:

```sh
catainer compat u24 android-safe
catainer shell u24
```

Reset that container back to automatic proot settings:

```sh
catainer compat u24 default
```

## Host-Root Mode

There are two different kinds of root:

- **Container root** is the default rootless mode. `catainer` uses `proot -0`, so the process looks like root inside Linux while still running as the Termux app user on Android.
- **Host-root mode** is optional and requires a rooted Android device with `su` or `tsu`. It re-executes `catainer` as real Android root and disables `proot -0`.

Enter with real Android root:

```sh
catainer root-shell u24
```

Run one command with real Android root:

```sh
catainer root-exec u24 -- id
catainer exec u24 --host-root -- id
```

Host-root mode can access more of the Android filesystem if you bind those paths yourself:

```sh
catainer mount u24 /data:/android-data
catainer root-shell u24
```

Only bind sensitive Android paths when you trust the container contents.

## Maintenance

Repair CA certificates if HTTPS tools report a missing certificate bundle, such as `curl: (77) error setting certificate file: /etc/ssl/certs/ca-certificates.crt`:

```sh
catainer certs u24 check
catainer certs u24 repair
catainer exec u24 -- curl -fsSL https://example.com/
```

If `dpkg` reports `mktemp: failed to create file via template '/data/data/.../.catainer/tmp/proot/ca-certificates.tmp.XXXXXX'`, update catainer and rerun the repair:

```sh
catainer update
catainer certs u24 repair
```

Back up, restore, clone, and rename:

```sh
catainer backup u24
catainer restore restored-u24 u24-catainer-backup-YYYYmmddHHMMSS.tar.gz
catainer clone u24 u24-test
catainer rename u24-test lab
catainer delete restored-u24 --force
```

Run a setup script after rootfs extraction:

```sh
cat > setup.sh <<'EOF'
#!/bin/sh
apt-get update
apt-get install -y git curl
EOF

catainer create u24 --post-install ./setup.sh
```

Each container keeps editable files under its own directory:

```text
~/.catainer/containers/u24/config
~/.catainer/containers/u24/mounts
~/.catainer/containers/u24/env
~/.catainer/containers/u24/proot-args
```

Mount specs use this format:

```text
SOURCE:TARGET
SOURCE:TARGET:ro
```

The `:ro` marker is accepted for readability. Enforcement depends on `proot`, so do not treat it as a hard security boundary.

## Rootfs Sources

- Ubuntu uses Ubuntu Base archives from `cdimage.ubuntu.com`.
- Alpine uses minirootfs archives from `dl-cdn.alpinelinux.org`.
- Debian uses debuerreotype OCI rootfs artifacts from `docker-debian-artifacts`, with `default` and `slim` variants.
- Arch Linux, Fedora, Kali, Linux Mint, openSUSE, Rocky Linux, AlmaLinux, Oracle Linux, Devuan, NixOS, Void Linux, and BusyBox use rootfs images from `images.linuxcontainers.org`.
- Custom installs use any tar rootfs URL supported by the installed `tar` helpers.

Supported archive formats include `.tar`, `.tar.gz`, `.tar.xz`, and `.tar.zst`.

## Supported Distros

```text
ubuntu
alpine
debian
archlinux   aliases: arch
fedora
kali
mint        aliases: linuxmint
opensuse
rockylinux  aliases: rocky
almalinux   aliases: alma
oracle
devuan
nixos
voidlinux   aliases: void
busybox
custom
```

## Troubleshooting

Diagnose host and container runtime settings:

```sh
catainer doctor u24 --run-tests
```

If entering a container fails with `execve("/usr/bin/env"): Function not implemented`, update catainer and check the runtime:

```sh
catainer update
catainer doctor u24 --run-tests
catainer shell u24
```

If the doctor output is sane but `proot` still fails on the device, use the Android-safe profile:

```sh
catainer compat u24 android-safe
catainer shell u24
```

## Release Notes

### 1.6.3

- Made `catainer update` the single recommended update command.
- `catainer update` updates catainer, `catainer update --check` checks catainer updates, and `catainer update NAME` upgrades packages inside a container.
- Kept `self-update`, `updates`, and `upgrade NAME` as compatibility aliases.

### 1.6.2

- Fixed guest `TMPDIR` leaking to the host-side proot temp directory, which could break Debian `ca-certificates` post-install scripts.
- Hardened `catainer certs repair` so it creates and uses guest `/tmp` before running package-manager commands.

### 1.6.1

- Removed the old login warning from documentation and runtime output.
- Restructured the README into clearer install, quick start, command reference, customization, compatibility, maintenance, sources, troubleshooting, and release notes sections.

### 1.6.0

- Added Bash and Zsh completion generation with `catainer completion bash|zsh`.
- Added `mounts`, `envs`, and enhanced `args` commands for listing, removing, and clearing per-container settings.
- Added `clone` and `rename` for container lifecycle management.
- Added `certs check|repair` to detect and repair missing CA bundles inside containers.
- Added `catainer --version --json` for scripts.
- Added GitHub Actions CI for syntax checks, ShellCheck, and README fence validation.

### 1.5.7

- Polished the command naming: `create`, `shell`, `exec`, `link`, `sources`, `releases`, `flavors`, `ls`, `inspect`, `updates`, and related aliases.
- Kept old command names working for compatibility.

### 1.5.6

- Added container-name shell prompts such as `root@u24:~#`.
- Kept the distro login-session path as the default for `catainer login`.

### 1.5.5

- Added distro MOTD display inside interactive shells, with a catainer fallback banner.
- Improved behavior when PAM does not set `MOTD_SHOWN`.

## Notes

- Android and `proot` limit ownership, device nodes, services, and some kernel features in rootless mode.
- Debian and Ubuntu containers include a `policy-rc.d` helper to reduce package-install failures from service startup attempts.
- Downloaded archives are cached under `~/.catainer/cache`.
- Containers are ordinary directories under `~/.catainer/containers`, so they can be inspected and backed up with standard tools.
