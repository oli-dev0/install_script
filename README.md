# Linux Mint Bootstrap

This is my post-install script for Linux Mint Cinnamon.

The goal is simple: take a fresh machine and get it close to my usual setup without turning the script into a mess. It installs the packages I want, restores the settings that are worth automating, keeps personal data in a separate secrets layer, and leaves a few manual reminders on the desktop for the things that should stay manual.

## What it does

- installs base apps with `apt`
- restores display, Cinnamon, Nemo, panel, keyboard, mouse, locale, and other desktop settings
- restores secret-backed data like Git identity, Wi-Fi profiles, SSH config, SSH keys, and private hosts entries
- restores some applet config and Timeshift defaults
- creates `~/Desktop/REMINDER.md` for the steps I still want to check manually

The script is meant to be rerunnable. Each step has a check first, then applies changes only when needed.

## Project shape

- `install.sh`
  Entry point. Parses arguments, loads helpers, asks for confirmation, checks sudo, and runs all sections.
- `libs/`
  Shared runtime helpers for prompts, step execution, logging, summaries, settings restores, and system helpers.
- `modules/`
  One file per installer section. Modules stay thin and mostly orchestrate steps.
- `config/`
  Source of truth for tracked settings, restore files, grouped gsettings, and templates.
- `config/secrets.sh`
  Local private values. This file is gitignored.
- `config/secrets/`
  Local private files such as SSH keys and private hosts entries. This directory is gitignored.

Current sections:

- `display`
- `network`
- `apps`
- `terminal`
- `git`
- `system`

## Before you run it

This script is built for Linux Mint Cinnamon. It may still work elsewhere, but that is not the target.

You should set up your local secrets first.

Use the tracked template:

```bash
cp config/secrets.example.sh config/secrets.sh
```

Then fill in what applies to you:

- `SECRET_GIT_USER_NAME`
- `SECRET_GIT_USER_EMAIL`
- `SECRET_GIT_IGNORE_GLOBAL_ENTRIES`
- `SECRET_NETWORK_WIFI_PROFILES`

Optional secret-backed files currently used by the installer:

- `config/secrets/hosts`
- `config/secrets/ssh/config`
- `config/secrets/ssh/id_ed25519`
- `config/secrets/ssh/id_ed25519.pub`

## Usage

Run the whole installer:

```bash
chmod +x install.sh
./install.sh
```

Useful options:

```bash
./install.sh --dry-run
./install.sh --yes
./install.sh --only apps
./install.sh --help
```

## What stays manual

Not everything belongs in a script.

The installer currently leaves manual reminders for a few things that are either machine-specific or simply not worth the extra code:

- add the WireGuard `.conf` file in `/etc/wireguard/`
- check Telegram install source
- connect Mailspring accounts
- set up Chrome profiles
- set up pinned apps on the panel
- verify the Timeshift drive
- configure the firewall manually

At the moment, firewall setup is intentionally manual. `ufw` is installed, but the script does not configure it.

Timeshift is partly automated:

- the base Timeshift config is restored
- once a backup device is selected, the script stops overwriting that file
- you still need to open Timeshift once and choose the device

## A few current defaults

Some of the current tracked defaults:

- projects directory: `~/Coding`
- timezone: `Europe/Brussels`
- display layout uses `HDMI-1` as primary and `eDP-1` to the right
- installed apps currently include `git`, `curl`, `wget`, `jq`, `htop`, `tree`, `unrar`, `ksnip`, `mailspring`, `spotify-client`, `simplenote`, `ufw`, and `wireguard`

## Validation

When I change the installer, I usually run:

```bash
bash -n install.sh libs/*.sh modules/*.sh config/config.sh config/system/*.sh config/display/*.sh
shellcheck install.sh libs/*.sh modules/*.sh config/config.sh config/system/*.sh config/display/*.sh
./install.sh --dry-run --yes
```

If I only changed one section, I run that section directly:

```bash
./install.sh --dry-run --yes --only system
```

## Notes

This project is intentionally conservative.

- small modules
- config separated from logic
- explicit step names
- no personal data in tracked files
- fewer abstractions unless they clearly reduce repetition

That matters more to me than trying to automate every last click.
