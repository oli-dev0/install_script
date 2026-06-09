# Linux Mint Bootstrap

Automated Linux Mint setup and configuration script.

This project installs applications, applies system settings, and configures a fresh Linux Mint installation to match my preferred environment.

## Features

* Modular architecture
* Idempotent execution (safe to run multiple times)
* Application installation
* System configuration
* GNOME/Cinnamon settings
* Development tools setup
* User preference configuration
* Logging and error handling

## Design Principles

* Single entry point: `install.sh`
* One responsibility per module
* Configuration separated from logic
* Defensive checks before making changes
* Re-runnable without causing duplicates
* Clear logging and error reporting

## Usage

```bash
chmod +x install.sh
./install.sh
```

## Goal

Turn a fresh Linux Mint installation into a fully configured workstation with a single command.
