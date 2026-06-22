#!/usr/bin/env bash
# shellcheck disable=SC2034

required_commands gsettings dconf locale locale-gen timedatectl stat grep sudo mkdir chmod cmp diff install mktemp cp rm

NEMO_DCONF_SOURCE="$ROOT_DIR/config/nemo/nemo-settings.conf"
NEMO_DCONF_PATH="/org/nemo/"
SYSTEM_MISC_SETTINGS_SOURCE="$ROOT_DIR/config/system/misc.sh"
SYSTEM_KEYBOARD_SETTINGS_SOURCE="$ROOT_DIR/config/system/keyboard.sh"
SYSTEM_KEYBOARD_SHORTCUTS_SOURCE="$ROOT_DIR/config/system/keyboard-shortcuts.conf"
SYSTEM_KEYBOARD_SHORTCUTS_DCONF_PATH="/org/cinnamon/desktop/keybindings/"
SYSTEM_MOUSE_SETTINGS_SOURCE="$ROOT_DIR/config/system/mouse.sh"
SYSTEM_NOTIFICATIONS_SETTINGS_SOURCE="$ROOT_DIR/config/system/notifications.sh"
SYSTEM_PANEL_SETTINGS_SOURCE="$ROOT_DIR/config/system/panel.sh"
SYSTEM_POWER_SETTINGS_SOURCE="$ROOT_DIR/config/system/power.sh"
SYSTEM_WINDOWS_SETTINGS_SOURCE="$ROOT_DIR/config/system/windows.sh"
SYSTEM_WINDOW_EFFECTS_SETTINGS_SOURCE="$ROOT_DIR/config/system/window-effects.sh"
SYSTEM_LOCALE_SOURCE="$ROOT_DIR/config/system/default-locale"
SYSTEM_LOCALE_TARGET="/etc/default/locale"
SYSTEM_SUPPORTED_LOCALES_SOURCE="$ROOT_DIR/config/system/supported-locales"
SYSTEM_SUPPORTED_LOCALES_TARGET="/var/lib/locales/supported.d/install-script"
SYSTEM_SECRET_HOSTS_SOURCE="$ROOT_DIR/config/secrets/hosts"
SYSTEM_SECRET_HOSTS_TARGET="/etc/hosts"
SYSTEM_WIREGUARD_APPLET_SOURCE="$ROOT_DIR/config/applets/wireguard@nicoulaj.net"
SYSTEM_WIREGUARD_APPLET_TARGET="$HOME/.local/share/cinnamon/applets/wireguard@nicoulaj.net"
SYSTEM_REMINDERS_SOURCE="$ROOT_DIR/config/system/reminders.md"
SYSTEM_REMINDERS_TARGET="$HOME/Desktop/REMINDER.md"
TIMESHIFT_CONFIG_SOURCE="$ROOT_DIR/config/timeshift/timeshift.json"
TIMESHIFT_CONFIG_TARGET="/etc/timeshift/timeshift.json"

SYSTEM_INITIAL_USER_FILE_RESTORE_STEPS=(
    "Restore Nemo desktop metadata|$ROOT_DIR/config/nemo/desktop-metadata|$HOME/.config/nemo/desktop-metadata|optional"
)

SYSTEM_DCONF_RESTORE_STEPS=(
    "Restore Nemo dconf settings|$NEMO_DCONF_SOURCE|$NEMO_DCONF_PATH|optional"
    "Restore keyboard shortcuts|$SYSTEM_KEYBOARD_SHORTCUTS_SOURCE|$SYSTEM_KEYBOARD_SHORTCUTS_DCONF_PATH|optional"
)

SYSTEM_EARLY_GSETTINGS_GROUP_STEPS=(
    "Set notifications|$SYSTEM_NOTIFICATIONS_SETTINGS_SOURCE|SYSTEM_NOTIFICATIONS_GSETTINGS|optional"
    "Set keyboard settings|$SYSTEM_KEYBOARD_SETTINGS_SOURCE|SYSTEM_KEYBOARD_GSETTINGS|optional"
    "Set mouse and touchpad settings|$SYSTEM_MOUSE_SETTINGS_SOURCE|SYSTEM_MOUSE_GSETTINGS|optional"
    "Set power settings|$SYSTEM_POWER_SETTINGS_SOURCE|SYSTEM_POWER_GSETTINGS|optional"
    "Set panel|$SYSTEM_PANEL_SETTINGS_SOURCE|SYSTEM_PANEL_GSETTINGS|optional"
)

SYSTEM_CUSTOM_STEPS=(
    "Set language and region|apply_system_language|system_language_is_configured|optional"
    "Set timezone|apply_system_timezone|system_timezone_is_configured|optional"
    "Prepare WireGuard directory|apply_wireguard_directory_setup|wireguard_directory_is_configured|optional"
    "Restore Timeshift settings|apply_timeshift_settings|timeshift_settings_are_configured|optional"
)

SYSTEM_OPTIONAL_SUDO_FILE_WITH_MODE_STEPS=(
    "Restore hosts file|$SYSTEM_SECRET_HOSTS_SOURCE|$SYSTEM_SECRET_HOSTS_TARGET|644|optional"
)

SYSTEM_LATE_GSETTINGS_GROUP_STEPS=(
    "Set window preferences|$SYSTEM_WINDOWS_SETTINGS_SOURCE|SYSTEM_WINDOWS_GSETTINGS|optional"
    "Set window effects|$SYSTEM_WINDOW_EFFECTS_SETTINGS_SOURCE|SYSTEM_WINDOW_EFFECTS_GSETTINGS|optional"
)

SYSTEM_FINAL_USER_FILE_RESTORE_STEPS=(
    "Restore calendar applet custom formats|$ROOT_DIR/config/applets/calendar@cinnamon.org/13.json|$HOME/.config/cinnamon/spices/calendar@cinnamon.org/13.json|optional"
    "Restore grouped window list applet config|$ROOT_DIR/config/applets/grouped-window-list@cinnamon.org/2.json|$HOME/.config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json|optional"
    "Restore menu applet config|$ROOT_DIR/config/applets/menu@cinnamon.org/0.json|$HOME/.config/cinnamon/spices/menu@cinnamon.org/0.json|optional"
    "Restore power applet config|$ROOT_DIR/config/applets/power@cinnamon.org/power@cinnamon.org.json|$HOME/.config/cinnamon/spices/power@cinnamon.org/power@cinnamon.org.json|optional"
)

SYSTEM_REMINDER_FILE_STEPS=(
    "Create reminders file|$SYSTEM_REMINDERS_SOURCE|$SYSTEM_REMINDERS_TARGET|optional"
)

SYSTEM_FINAL_USER_DIRECTORY_RESTORE_STEPS=(
    "Restore WireGuard applet|$SYSTEM_WIREGUARD_APPLET_SOURCE|$SYSTEM_WIREGUARD_APPLET_TARGET|optional"
)

SYSTEM_MANUAL_STEPS=(
    "Select Timeshift backup device|Open Timeshift, select the snapshot device, and confirm the settings. This step is complete when Timeshift has written a non-empty backup device UUID.|timeshift_backup_device_is_selected|optional"
)

SYSTEM_SECTION_TOTAL=$(( \
    $(declared_array_length "SYSTEM_INITIAL_USER_FILE_RESTORE_STEPS") + \
    $(declared_array_length "SYSTEM_DCONF_RESTORE_STEPS") + \
    $(settings_array_length "$SYSTEM_MISC_SETTINGS_SOURCE" "SYSTEM_MISC_GSETTINGS_GROUPS") + \
    $(declared_array_length "SYSTEM_EARLY_GSETTINGS_GROUP_STEPS") + \
    $(declared_array_length "SYSTEM_CUSTOM_STEPS") + \
    $(declared_array_length "SYSTEM_OPTIONAL_SUDO_FILE_WITH_MODE_STEPS") + \
    $(declared_array_length "SYSTEM_LATE_GSETTINGS_GROUP_STEPS") + \
    $(declared_array_length "SYSTEM_FINAL_USER_FILE_RESTORE_STEPS") + \
    $(declared_array_length "SYSTEM_REMINDER_FILE_STEPS") + \
    $(declared_array_length "SYSTEM_FINAL_USER_DIRECTORY_RESTORE_STEPS") + \
    $(declared_array_length "SYSTEM_MANUAL_STEPS") \
))

section_start "System Settings" "$SYSTEM_SECTION_TOTAL"

system_language_is_configured() {
    sudo_file_is_restored "$SYSTEM_LOCALE_SOURCE" "$SYSTEM_LOCALE_TARGET" || return 1
    sudo_file_is_restored "$SYSTEM_SUPPORTED_LOCALES_SOURCE" "$SYSTEM_SUPPORTED_LOCALES_TARGET" || return 1
    locale -a | grep -Fxq 'en_US.utf8' || return 1
    locale -a | grep -Fxq 'en_AU.utf8' || return 1
    locale -a | grep -Fxq 'nl_BE.utf8'
}

apply_system_language() {
    restore_sudo_file "$SYSTEM_LOCALE_SOURCE" "$SYSTEM_LOCALE_TARGET" || return 1
    restore_sudo_file "$SYSTEM_SUPPORTED_LOCALES_SOURCE" "$SYSTEM_SUPPORTED_LOCALES_TARGET" || return 1
    sudo locale-gen
}

system_timezone_is_configured() {
    [[ -f /etc/timezone ]] || return 1
    [[ "$(cat /etc/timezone)" == "$SYSTEM_TIMEZONE" ]] || return 1
    [[ "$(readlink -f /etc/localtime)" == "/usr/share/zoneinfo/$SYSTEM_TIMEZONE" ]]
}

apply_system_timezone() {
    sudo timedatectl set-timezone "$SYSTEM_TIMEZONE"
}

wireguard_directory_is_configured() {
    [[ -d /etc/wireguard ]] || return 1
    [[ "$(stat -c '%a' /etc/wireguard)" == "755" ]]
}

apply_wireguard_directory_setup() {
    sudo mkdir -p /etc/wireguard
    sudo chmod 755 /etc/wireguard
}

timeshift_settings_are_configured() {
    [[ -f "$TIMESHIFT_CONFIG_TARGET" ]] || return 1

    if timeshift_backup_device_is_selected; then
        return 0
    fi

    sudo_file_is_restored "$TIMESHIFT_CONFIG_SOURCE" "$TIMESHIFT_CONFIG_TARGET"
}

apply_timeshift_settings() {
    restore_sudo_file "$TIMESHIFT_CONFIG_SOURCE" "$TIMESHIFT_CONFIG_TARGET"
}

timeshift_backup_device_is_selected() {
    [[ -f "$TIMESHIFT_CONFIG_TARGET" ]] || return 1
    sudo grep -Eq '"backup_device_uuid"[[:space:]]*:[[:space:]]*"[^"]+"' "$TIMESHIFT_CONFIG_TARGET"
}

run_restore_user_file_steps_from_entries "SYSTEM_INITIAL_USER_FILE_RESTORE_STEPS"
run_restore_dconf_steps_from_entries "SYSTEM_DCONF_RESTORE_STEPS"

run_labeled_gsettings_group_steps \
    "$SYSTEM_MISC_SETTINGS_SOURCE" \
    "SYSTEM_MISC_GSETTINGS_GROUPS" \
    "optional"

run_gsettings_group_steps_from_entries "SYSTEM_EARLY_GSETTINGS_GROUP_STEPS"
run_custom_steps_from_entries "SYSTEM_CUSTOM_STEPS"
run_optional_restore_sudo_file_with_mode_steps_from_entries "SYSTEM_OPTIONAL_SUDO_FILE_WITH_MODE_STEPS"
run_gsettings_group_steps_from_entries "SYSTEM_LATE_GSETTINGS_GROUP_STEPS"
run_restore_user_file_steps_from_entries "SYSTEM_FINAL_USER_FILE_RESTORE_STEPS"
run_reminder_file_steps_from_entries "SYSTEM_REMINDER_FILE_STEPS"
run_restore_user_directory_steps_from_entries "SYSTEM_FINAL_USER_DIRECTORY_RESTORE_STEPS"
run_manual_steps_from_entries "SYSTEM_MANUAL_STEPS"

section_end "System Settings"
