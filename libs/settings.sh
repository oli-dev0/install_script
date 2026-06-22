#!/usr/bin/env bash

load_settings_file() {
    local settings_file="$1"
    local array_name="$2"

    if [[ ! -f "$settings_file" ]]; then
        echo "Missing source file: $settings_file"
        return 1
    fi

    # shellcheck source=/dev/null
    source "$settings_file"

    declare -p "$array_name" &>/dev/null || return 1
}

declared_array_length() {
    local array_name="$1"

    if ! declare -p "$array_name" &>/dev/null; then
        printf '0\n'
        return 0
    fi

    # shellcheck disable=SC2178
    # shellcheck disable=SC2178
    local -n entries="$array_name"
    printf '%s\n' "${#entries[@]}"
}

settings_array_length() {
    local settings_file="$1"
    local array_name="$2"

    if ! load_settings_file "$settings_file" "$array_name"; then
        printf '0\n'
        return 0
    fi

    # shellcheck disable=SC2178
    # shellcheck disable=SC2178
    local -n entries="$array_name"
    printf '%s\n' "${#entries[@]}"
}

gsettings_entry_is_applied() {
    local entry="$1"
    local schema key expected actual

    IFS='|' read -r schema key expected <<< "$entry"
    actual="$(gsettings get "$schema" "$key")"
    [[ "$actual" == "$expected" ]]
}

gsettings_entries_are_applied() {
    local settings_file="$1"
    local array_name="$2"
    local entry

    load_settings_file "$settings_file" "$array_name" || return 1

    # shellcheck disable=SC2178
    # shellcheck disable=SC2178
    local -n entries="$array_name"
    [[ ${#entries[@]} -gt 0 ]] || return 1

    for entry in "${entries[@]}"; do
        gsettings_entry_is_applied "$entry" || return 1
    done
}

apply_gsettings_entries() {
    local settings_file="$1"
    local array_name="$2"
    local entry
    local schema key expected

    load_settings_file "$settings_file" "$array_name" || return 1

    # shellcheck disable=SC2178
    # shellcheck disable=SC2178
    local -n entries="$array_name"
    [[ ${#entries[@]} -gt 0 ]] || return 1

    for entry in "${entries[@]}"; do
        IFS='|' read -r schema key expected <<< "$entry"
        gsettings set "$schema" "$key" "$expected"
    done
}

gsettings_group_label() {
    local group="$1"

    printf '%s\n' "${group%%;*}"
}

gsettings_group_entry_is_applied() {
    local group="$1"
    local entries_blob
    local entry
    local -a entries

    entries_blob="${group#*;}"
    IFS=';' read -r -a entries <<< "$entries_blob"

    for entry in "${entries[@]}"; do
        gsettings_entry_is_applied "$entry" || return 1
    done
}

apply_gsettings_group_entry() {
    local group="$1"
    local entries_blob
    local entry
    local schema key expected
    local -a entries

    entries_blob="${group#*;}"
    IFS=';' read -r -a entries <<< "$entries_blob"

    for entry in "${entries[@]}"; do
        IFS='|' read -r schema key expected <<< "$entry"
        gsettings set "$schema" "$key" "$expected"
    done
}

run_labeled_gsettings_group_steps() {
    local settings_file="$1"
    local array_name="$2"
    local criticality="${3:-optional}"
    local group
    local label
    local escaped_group

    load_settings_file "$settings_file" "$array_name" || return 1

    local -n groups="$array_name"
    [[ ${#groups[@]} -gt 0 ]] || return 1

    for group in "${groups[@]}"; do
        label="$(gsettings_group_label "$group")"
        printf -v escaped_group '%q' "$group"

        run_step \
            "$label" \
            "apply_gsettings_group_entry $escaped_group" \
            "gsettings_group_entry_is_applied $escaped_group" \
            "$criticality"
    done
}

run_gsettings_group_steps_from_entries() {
    local array_name="$1"
    local entry
    local title settings_file settings_array criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title settings_file settings_array criticality <<< "$entry"
        run_gsettings_group_step "$title" "$settings_file" "$settings_array" "${criticality:-optional}"
    done
}

restore_user_file() {
    local source_file="$1"
    local target_file="$2"

    if [[ ! -f "$source_file" ]]; then
        echo "Missing source file: $source_file"
        return 1
    fi

    backup_file "$target_file"
    mkdir -p "$(dirname "$target_file")"
    cp "$source_file" "$target_file"
}

restore_user_directory() {
    local source_dir="$1"
    local target_dir="$2"

    if [[ ! -d "$source_dir" ]]; then
        echo "Missing source directory: $source_dir"
        return 1
    fi

    backup_file "$target_dir"
    mkdir -p "$(dirname "$target_dir")"
    rm -rf "$target_dir"
    cp -a "$source_dir" "$target_dir"
}

restore_user_file_with_mode() {
    local source_file="$1"
    local target_file="$2"
    local file_mode="$3"

    if [[ ! -f "$source_file" ]]; then
        echo "Missing source file: $source_file"
        return 1
    fi

    backup_file "$target_file"
    mkdir -p "$(dirname "$target_file")"
    install -m "$file_mode" "$source_file" "$target_file"
}

user_file_is_restored() {
    local source_file="$1"
    local target_file="$2"

    [[ -f "$source_file" ]] || return 1
    [[ -f "$target_file" ]] || return 1
    cmp -s "$source_file" "$target_file"
}

user_directory_is_restored() {
    local source_dir="$1"
    local target_dir="$2"

    [[ -d "$source_dir" ]] || return 1
    [[ -d "$target_dir" ]] || return 1
    diff -qr "$source_dir" "$target_dir" >/dev/null 2>&1
}

user_file_with_mode_is_restored() {
    local source_file="$1"
    local target_file="$2"
    local expected_mode="$3"
    local actual_mode

    user_file_is_restored "$source_file" "$target_file" || return 1
    actual_mode="$(stat -c '%a' "$target_file")"
    [[ "$actual_mode" == "$expected_mode" ]]
}

restore_sudo_file() {
    local source_file="$1"
    local target_file="$2"

    if [[ ! -f "$source_file" ]]; then
        echo "Missing source file: $source_file"
        return 1
    fi

    backup_file "$target_file"
    sudo mkdir -p "$(dirname "$target_file")"
    sudo cp "$source_file" "$target_file"
}

restore_sudo_file_with_mode() {
    local source_file="$1"
    local target_file="$2"
    local file_mode="$3"

    if [[ ! -f "$source_file" ]]; then
        echo "Missing source file: $source_file"
        return 1
    fi

    backup_file "$target_file"
    sudo mkdir -p "$(dirname "$target_file")"
    sudo install -m "$file_mode" "$source_file" "$target_file"
}

sudo_file_is_restored() {
    local source_file="$1"
    local target_file="$2"

    [[ -f "$source_file" ]] || return 1
    [[ -f "$target_file" ]] || return 1
    sudo cmp -s "$source_file" "$target_file"
}

sudo_file_with_mode_is_restored() {
    local source_file="$1"
    local target_file="$2"
    local expected_mode="$3"
    local actual_mode

    sudo_file_is_restored "$source_file" "$target_file" || return 1
    actual_mode="$(stat -c '%a' "$target_file")"
    [[ "$actual_mode" == "$expected_mode" ]]
}

dconf_backup_path() {
    local dconf_path="$1"
    local normalized

    normalized="${dconf_path#/}"
    normalized="${normalized%/}"
    normalized="${normalized//\//-}"
    printf '%s/dconf/%s.conf\n' "$BACKUP_RUN_DIR" "$normalized"
}

backup_dconf_path() {
    local dconf_path="$1"
    local backup_file_path

    backup_file_path="$(dconf_backup_path "$dconf_path")"
    mkdir -p "$(dirname "$backup_file_path")"
    dconf dump "$dconf_path" > "$backup_file_path" 2>/dev/null
}

restore_dconf_file() {
    local source_file="$1"
    local dconf_path="$2"

    if [[ ! -f "$source_file" ]]; then
        echo "Missing source file: $source_file"
        return 1
    fi

    backup_dconf_path "$dconf_path"
    dconf load "$dconf_path" < "$source_file"
}

dconf_file_is_restored() {
    local source_file="$1"
    local dconf_path="$2"
    local current_dump

    [[ -f "$source_file" ]] || return 1

    current_dump="$(mktemp)"
    dconf dump "$dconf_path" > "$current_dump" 2>/dev/null
    cmp -s "$source_file" "$current_dump"
    rm -f "$current_dump"
}

run_restore_user_file_step() {
    local title="$1"
    local source_file="$2"
    local target_file="$3"
    local criticality="${4:-optional}"

    run_step \
        "$title" \
        "restore_user_file \"$source_file\" \"$target_file\"" \
        "user_file_is_restored \"$source_file\" \"$target_file\"" \
        "$criticality"
}

run_reminder_file_step() {
    local title="$1"
    local source_file="$2"
    local target_file="$3"
    local criticality="${4:-optional}"

    run_restore_user_file_step "$title" "$source_file" "$target_file" "$criticality"
}

run_reminder_file_steps_from_entries() {
    local array_name="$1"

    run_restore_user_file_steps_from_entries "$array_name"
}

run_restore_user_directory_step() {
    local title="$1"
    local source_dir="$2"
    local target_dir="$3"
    local criticality="${4:-optional}"

    run_step \
        "$title" \
        "restore_user_directory \"$source_dir\" \"$target_dir\"" \
        "user_directory_is_restored \"$source_dir\" \"$target_dir\"" \
        "$criticality"
}

run_restore_user_directory_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_dir target_dir criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_dir target_dir criticality <<< "$entry"
        run_restore_user_directory_step "$title" "$source_dir" "$target_dir" "${criticality:-optional}"
    done
}

run_restore_user_file_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_file target_file criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_file target_file criticality <<< "$entry"
        run_restore_user_file_step "$title" "$source_file" "$target_file" "${criticality:-optional}"
    done
}

run_restore_user_file_with_mode_step() {
    local title="$1"
    local source_file="$2"
    local target_file="$3"
    local file_mode="$4"
    local criticality="${5:-optional}"

    run_step \
        "$title" \
        "restore_user_file_with_mode \"$source_file\" \"$target_file\" \"$file_mode\"" \
        "user_file_with_mode_is_restored \"$source_file\" \"$target_file\" \"$file_mode\"" \
        "$criticality"
}

run_optional_restore_user_file_with_mode_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_file target_file file_mode criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_file target_file file_mode criticality <<< "$entry"

        if [[ -f "$source_file" ]]; then
            run_restore_user_file_with_mode_step "$title" "$source_file" "$target_file" "$file_mode" "${criticality:-optional}"
        else
            run_skipped_step "$title" "Missing $source_file"
        fi
    done
}

run_restore_sudo_file_step() {
    local title="$1"
    local source_file="$2"
    local target_file="$3"
    local criticality="${4:-optional}"

    run_step \
        "$title" \
        "restore_sudo_file \"$source_file\" \"$target_file\"" \
        "sudo_file_is_restored \"$source_file\" \"$target_file\"" \
        "$criticality"
}

run_restore_sudo_file_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_file target_file criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_file target_file criticality <<< "$entry"
        run_restore_sudo_file_step "$title" "$source_file" "$target_file" "${criticality:-optional}"
    done
}

run_restore_sudo_file_with_mode_step() {
    local title="$1"
    local source_file="$2"
    local target_file="$3"
    local file_mode="$4"
    local criticality="${5:-optional}"

    run_step \
        "$title" \
        "restore_sudo_file_with_mode \"$source_file\" \"$target_file\" \"$file_mode\"" \
        "sudo_file_with_mode_is_restored \"$source_file\" \"$target_file\" \"$file_mode\"" \
        "$criticality"
}

run_optional_restore_sudo_file_with_mode_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_file target_file file_mode criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_file target_file file_mode criticality <<< "$entry"

        if [[ -f "$source_file" ]]; then
            run_restore_sudo_file_with_mode_step "$title" "$source_file" "$target_file" "$file_mode" "${criticality:-optional}"
        else
            run_skipped_step "$title" "Missing $source_file"
        fi
    done
}

run_restore_dconf_step() {
    local title="$1"
    local source_file="$2"
    local dconf_path="$3"
    local criticality="${4:-optional}"

    run_step \
        "$title" \
        "restore_dconf_file \"$source_file\" \"$dconf_path\"" \
        "dconf_file_is_restored \"$source_file\" \"$dconf_path\"" \
        "$criticality"
}

run_restore_dconf_steps_from_entries() {
    local array_name="$1"
    local entry
    local title source_file dconf_path criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title source_file dconf_path criticality <<< "$entry"
        run_restore_dconf_step "$title" "$source_file" "$dconf_path" "${criticality:-optional}"
    done
}

run_gsettings_group_step() {
    local title="$1"
    local settings_file="$2"
    local array_name="$3"
    local criticality="${4:-optional}"

    run_step \
        "$title" \
        "apply_gsettings_entries \"$settings_file\" \"$array_name\"" \
        "gsettings_entries_are_applied \"$settings_file\" \"$array_name\"" \
        "$criticality"
}

run_custom_steps_from_entries() {
    local array_name="$1"
    local entry
    local title change_cmd check_cmd criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title change_cmd check_cmd criticality <<< "$entry"
        run_step "$title" "$change_cmd" "$check_cmd" "${criticality:-optional}"
    done
}

run_manual_steps_from_entries() {
    local array_name="$1"
    local entry
    local title instructions check_cmd criticality

    # shellcheck disable=SC2178
    local -n entries="$array_name"

    for entry in "${entries[@]}"; do
        IFS='|' read -r title instructions check_cmd criticality <<< "$entry"
        run_manual_step "$title" "$instructions" "$check_cmd" "${criticality:-optional}"
    done
}
