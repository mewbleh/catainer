# catainer

`catainer` is a single-file Termux container manager for installing and running Linux distributions with `proot`.
It is designed for Android devices where traditional root access, Docker, systemd, and privileged mounts are not available.

No root is required; rooted devices can opt in to host-root execution when they need real Android root privileges.

Current version: `1.5.7`

## Features

- Create Ubuntu Base, Alpine minirootfs, Debian debuerreotype rootfs images, Linux Containers images, or custom rootfs containers.
- List and select distro releases before creating a container.
- Choose distro flavors, including Debian `default` and `slim`.
- Run containers without root by using `proot` and isolated root filesystems under `~/.catainer`.
- Show a command overview, a quick status report, colorized output, and a custom download progress bar.
- Enter an interactive shell or run one-off commands inside a container.
- Try distro PAM/session tools experimentally with `catainer login NAME`.
- Create direct container links, such as `u24`, so common containers can be entered without typing `catainer shell u24`.
- Show distro MOTD files inside interactive shells, with a lightweight catainer banner as fallback.
- Show clean container prompts such as `root@u24:~#` even when proot reports the Android hostname.
- Configure per-container bind mounts, environment variables, hostnames, default users, and extra `proot` arguments.
- Use optional host-root mode on rooted devices through `su` or `tsu`.
- Diagnose Termux/proot compatibility issues with `catainer doctor`.
- Save proot compatibility profiles per container with `catainer compat`.
- Run post-install hooks for repeatable setup.
- Back up, restore, upgrade, inspect, and delete containers from one CLI.
- Check for catainer updates and self-update atomically from the configured GitHub source.

## Requirements

Install Termux from a trusted source, then install the runtime dependencies:

```sh
pkg install -y proot tar curl ca-certificates xz-utils gzip zstd coreutils
```

You can also let `catainer` install them:

```sh
./catainer setup
```

## Installation

Install directly from GitHub:

```sh
curl -fsSL https://raw.githubusercontent.com/mewbleh/catainer/main/install.sh | sh
```

Or install from a local checkout:

```sh
chmod +x ./catainer
./catainer self-install
```

By default, `self-install` copies the script to `$PREFIX/bin/catainer` in Termux.
Restart the shell or refresh command lookup after installing:

```sh
hash -r
```

## Quick Start

Print the command overview or status report:

```sh
catainer
catainer status
catainer --no-color
catainer --plain
```

`catainer` is command-first: use explicit subcommands such as `create`, `shell`, `exec`, `ls`, and `status`.

List available distro releases:

```sh
catainer releases ubuntu
catainer releases alpine
catainer releases debian
catainer releases archlinux
catainer releases fedora
catainer releases opensuse
```

List flavors:

```sh
catainer flavors debian
catainer flavors voidlinux
```

Install Ubuntu 24.04:

```sh
catainer create u24 --distro ubuntu --release 24.04
catainer shell u24
```

Try the distro PAM/session path:

```sh
catainer login u24
catainer login u24 --method su
catainer distro-login u24
```

Create a direct link:

```sh
catainer link u24
u24
u24 uname -a
```

Choose release and variant from a prompt:

```sh
catainer create lab --distro debian --select
```

Install Debian slim directly:

```sh
catainer create debian-slim --distro debian --release bookworm --variant slim
```

Install Arch Linux, Fedora, Kali, or openSUSE:

```sh
catainer create arch --distro archlinux
catainer create fedora --distro fedora --release 44
catainer create kali --distro kali
catainer create tumbleweed --distro opensuse --release tumbleweed
```

Create a default non-root user:

```sh
catainer create u24-dev --distro ubuntu --release 24.04 --user dev
catainer shell u24-dev
```

Run a single command:

```sh
catainer exec u24 -- apt-get update
```

Delete an installed container:

```sh
catainer delete u24 --force
```

Check or apply catainer updates:

```sh
catainer updates
catainer self-update
```

Install Alpine:

```sh
catainer create alpine --distro alpine
catainer shell alpine
```

Use a custom rootfs archive:

```sh
catainer create lab \
  --distro custom \
  --url https://example.com/rootfs.tar.xz \
  --sha256 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

## Commands

```text
catainer setup
catainer sources
catainer releases DISTRO [--arch ARCH] [--mirror URL]
catainer flavors DISTRO [--release RELEASE] [--arch ARCH] [--mirror URL]
catainer create NAME [options]
catainer shell NAME [--user USER] [--workdir DIR] [--host-root] [-- COMMAND...]
catainer exec NAME [--user USER] [--workdir DIR] [--host-root] -- COMMAND...
catainer root-shell NAME [--user USER] [--workdir DIR] [-- COMMAND...]
catainer root-exec NAME [--user USER] [--workdir DIR] -- COMMAND...
catainer login NAME [--user USER] [--workdir DIR] [--host-root] [--method auto|runuser|su|login]
catainer link NAME [ALIAS] [--target DIR] [--force]
catainer upgrade NAME
catainer status
catainer ls
catainer inspect NAME
catainer compat NAME [show|android-safe|default]
catainer doctor [NAME] [--host-root] [--run-tests]
catainer mount NAME SOURCE:TARGET[:ro]
catainer env NAME KEY=VALUE
catainer args NAME ARG...
catainer set NAME KEY=VALUE
catainer backup NAME [OUTPUT.tar.gz]
catainer restore NAME ARCHIVE.tar.gz [--force]
catainer delete NAME [--force]
catainer updates [--refresh]
catainer self-update [--target PATH] [--force]
catainer self-install [TARGET]
```

Compatibility aliases remain supported:

```text
deps=setup, distros=sources, versions=releases, variants=flavors
install=create, enter=shell, run=exec, shortcut=link
list=ls, info=inspect, proot-arg=args, config=set
update=upgrade, remove=delete, check-update=updates
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

Persist a proot compatibility fallback for one container:

```sh
catainer compat u24 android-safe
catainer shell u24
```

Reset that container back to automatic proot settings:

```sh
catainer compat u24 default
```

## Create Options

```text
-d, --distro NAME       distro name, e.g. ubuntu, fedora, archlinux, kali
-r, --release RELEASE   distro release
-a, --arch ARCH         rootfs architecture
    --url URL           custom rootfs archive URL, or built-in URL override
    --sha256 SHA256     verify a downloaded archive
    --mirror URL        override the distro mirror or base URL
    --variant VARIANT   distro variant
    --hostname NAME     hostname inside the container
-u, --user USER         create and use a default container user
-m, --mount SPEC        add a bind mount
-e, --env KEY=VALUE     add an environment variable
    --post-install FILE run a host-side script inside the container after install
    --no-default-mounts skip default Termux and Android mounts
    --select            force the release and variant picker
    --no-select         use defaults without prompting
    --skip-deps         do not install missing Termux packages automatically
-f, --force             replace an existing local container
```

## Customization

Add a bind mount:

```sh
catainer mount u24 /sdcard/projects:/projects
```

Add an environment variable:

```sh
catainer env u24 EDITOR=nano
```

Add raw `proot` arguments:

```sh
catainer args u24 --sysvipc
```

Create a direct launcher for a container:

```sh
catainer link u24
catainer link u24 ubuntu --target "$PREFIX/bin" --force
```

The generated launcher enters the container when run without arguments. If arguments are passed, it runs them as a command inside the container:

```sh
u24
u24 apt-get update
```

Catainer also writes `/etc/catainer-motd`, `/etc/profile.d/catainer.sh`, `/usr/local/bin/catainer-motd`, and `/usr/local/bin/catainer-info` inside each rootfs.
Normal Debian and Ubuntu login banners usually depend on a full login stack such as PAM.
Catainer starts shells directly through `proot` or session tools such as `runuser`, so it displays distro MOTD files itself when PAM does not set `MOTD_SHOWN`.
If no distro MOTD exists, catainer shows its own small banner without replacing the distro's `/etc/motd`.
Catainer also sets the Bash/Zsh prompt to use the container name, for example `root@u24:~#`.
Set `CATAINER_PROMPT=0` with `catainer env NAME CATAINER_PROMPT=0` to keep the distro's default prompt.
If you want to test the distro PAM/session path, use `catainer login NAME`.
The default `auto` method tries `runuser -l USER`, then `su - USER`, then raw `/bin/login -f USER`.
To force the raw `/bin/login` test, use `catainer login NAME --method login` or `catainer distro-login NAME`.
This is experimental because login/session tools may expect real TTY, utmp/wtmp, PAM, or root behavior that varies across Android kernels and rootfs images.
If it fails, use `catainer shell NAME`.

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

Control catainer update checks:

```sh
CAT_UPDATE_NOTIFY=never catainer
CAT_UPDATE_TTL=3600 catainer
CATAINER_UPDATE_URL=https://raw.githubusercontent.com/mewbleh/catainer/main/catainer catainer self-update
```

Update checks are cached under `~/.catainer/update-check`.

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

If entering a container fails with `execve("/usr/bin/env"): Function not implemented`, update catainer and check the launcher:

```sh
catainer self-update
catainer doctor u24 --run-tests
catainer shell u24
```

If the doctor output is sane but `proot` still fails on the device, save the stricter Android profile:

```sh
catainer compat u24 android-safe
catainer shell u24
```

`catainer doctor NAME --run-tests` prints the detected shell, effective proot compatibility environment, command shape, and a direct shell execution test.

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

## Root Support

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
```

The equivalent long form is:

```sh
catainer exec u24 --host-root -- id
```

Host-root mode can access more of the Android filesystem if you bind those paths yourself:

```sh
catainer mount u24 /data:/android-data
catainer root-shell u24
```

Only bind sensitive Android paths when you trust the container contents.

## Post-Install Hooks

Create a setup script on the Termux side:

```sh
cat > setup.sh <<'EOF'
#!/bin/sh
apt-get update
apt-get install -y git curl
EOF
```

Run it during installation:

```sh
catainer create u24 --post-install ./setup.sh
```

## Backups

```sh
catainer backup u24
catainer restore restored-u24 u24-catainer-backup-YYYYmmddHHMMSS.tar.gz
catainer delete restored-u24 --force
```

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

## Notes

- Android and `proot` limit ownership, device nodes, services, and some kernel features in rootless mode.
- Debian and Ubuntu containers include a `policy-rc.d` helper to reduce package-install failures from service startup attempts.
- Downloaded archives are cached under `~/.catainer/cache`.
- Containers are ordinary directories under `~/.catainer/containers`, so they can be inspected and backed up with standard tools.
