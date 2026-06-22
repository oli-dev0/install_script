#!/usr/bin/env bash
# shellcheck disable=SC2034

required_commands xrandr gsettings dconf grep cmp mktemp

DISPLAY_NIGHT_LIGHT_SOURCE="$ROOT_DIR/config/display/night-light.conf"
DISPLAY_NIGHT_LIGHT_DCONF_PATH="/org/cinnamon/settings-daemon/plugins/color/"
DISPLAY_MISC_SETTINGS_SOURCE="$ROOT_DIR/config/display/misc.sh"

DISPLAY_CUSTOM_STEPS=(
    "Set display layout|apply_display_layout|display_layout_is_configured|critical"
)

DISPLAY_DCONF_RESTORE_STEPS=(
    "Restore display night light settings|$DISPLAY_NIGHT_LIGHT_SOURCE|$DISPLAY_NIGHT_LIGHT_DCONF_PATH|optional"
)

DISPLAY_SECTION_TOTAL=$(( \
    $(declared_array_length "DISPLAY_CUSTOM_STEPS") + \
    $(settings_array_length "$DISPLAY_MISC_SETTINGS_SOURCE" "DISPLAY_MISC_GSETTINGS_GROUPS") + \
    $(declared_array_length "DISPLAY_DCONF_RESTORE_STEPS") \
))

section_start "Display Settings" "$DISPLAY_SECTION_TOTAL"

display_internal_offset_x() {
    local width

    width="${DISPLAY_RESOLUTION%x*}"
    printf '%s\n' "$width"
}

display_layout_is_configured() {
    local internal_offset_x
    local external_line
    local internal_line

    internal_offset_x="$(display_internal_offset_x)"
    external_line="$(xrandr --query | grep "^${DISPLAY_EXTERNAL_OUTPUT} connected primary" || true)"
    internal_line="$(xrandr --query | grep "^${DISPLAY_INTERNAL_OUTPUT} connected" || true)"

    [[ "$external_line" == *"${DISPLAY_RESOLUTION}+0+0"* ]] || return 1
    [[ "$external_line" == *"(normal "* ]] || return 1
    [[ "$internal_line" == *"${DISPLAY_RESOLUTION}+${internal_offset_x}+0"* ]] || return 1
    [[ "$internal_line" == *"(normal "* ]] || return 1
    [[ "$external_line" != *" disconnected"* ]] || return 1
    [[ "$internal_line" != *" disconnected"* ]] || return 1
}

apply_display_layout() {
    xrandr \
        --output "$DISPLAY_EXTERNAL_OUTPUT" --primary --mode "$DISPLAY_RESOLUTION" --rate "$DISPLAY_REFRESH_RATE" --rotate normal \
        --output "$DISPLAY_INTERNAL_OUTPUT" --mode "$DISPLAY_RESOLUTION" --rate "$DISPLAY_REFRESH_RATE" --right-of "$DISPLAY_EXTERNAL_OUTPUT" --rotate normal
}

run_custom_steps_from_entries "DISPLAY_CUSTOM_STEPS"

run_labeled_gsettings_group_steps \
    "$DISPLAY_MISC_SETTINGS_SOURCE" \
    "DISPLAY_MISC_GSETTINGS_GROUPS" \
    "critical"

run_restore_dconf_steps_from_entries "DISPLAY_DCONF_RESTORE_STEPS"

section_end "Display Settings"
