#!/usr/bin/env bash
# shellcheck disable=SC2034

required_commands mkdir install stat cmp

TERMINAL_GHOSTTY_CONFIG_SOURCE="$ROOT_DIR/config/ghostty/config"
TERMINAL_SECRET_SSH_CONFIG_SOURCE="$ROOT_DIR/config/secrets/ssh/config"
TERMINAL_SECRET_SSH_PRIVATE_KEY_SOURCE="$ROOT_DIR/config/secrets/ssh/id_ed25519"
TERMINAL_SECRET_SSH_PUBLIC_KEY_SOURCE="$ROOT_DIR/config/secrets/ssh/id_ed25519.pub"

projects_directory_exists() {
    [[ -d "$PROJECTS_DIR" ]]
}

create_projects_directory() {
    mkdir -p "$PROJECTS_DIR"
}

TERMINAL_CUSTOM_STEPS=(
    "Create projects directory|create_projects_directory|projects_directory_exists|optional"
)

TERMINAL_USER_FILE_STEPS=(
    "Restore Ghostty config|$TERMINAL_GHOSTTY_CONFIG_SOURCE|$HOME/.config/ghostty/config|optional"
)

TERMINAL_OPTIONAL_USER_FILE_WITH_MODE_STEPS=(
    "Restore SSH config|$TERMINAL_SECRET_SSH_CONFIG_SOURCE|$HOME/.ssh/config|600|optional"
    "Restore SSH private key|$TERMINAL_SECRET_SSH_PRIVATE_KEY_SOURCE|$HOME/.ssh/id_ed25519|600|optional"
    "Restore SSH public key|$TERMINAL_SECRET_SSH_PUBLIC_KEY_SOURCE|$HOME/.ssh/id_ed25519.pub|644|optional"
)

TERMINAL_SECTION_TOTAL=$(( \
    $(declared_array_length "TERMINAL_CUSTOM_STEPS") + \
    $(declared_array_length "TERMINAL_USER_FILE_STEPS") + \
    $(declared_array_length "TERMINAL_OPTIONAL_USER_FILE_WITH_MODE_STEPS") \
))

section_start "Terminal Settings" "$TERMINAL_SECTION_TOTAL"

run_custom_steps_from_entries "TERMINAL_CUSTOM_STEPS"
run_restore_user_file_steps_from_entries "TERMINAL_USER_FILE_STEPS"
run_optional_restore_user_file_with_mode_steps_from_entries "TERMINAL_OPTIONAL_USER_FILE_WITH_MODE_STEPS"

section_end "Terminal Settings"
