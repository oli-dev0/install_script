#!/usr/bin/env bash
# shellcheck disable=SC2034

required_commands git grep touch

GIT_IGNORE_GLOBAL_FILE="$HOME/.gitignore_global"

git_identity_secrets_available() {
    [[ -n "${SECRET_GIT_USER_NAME:-}" && -n "${SECRET_GIT_USER_EMAIL:-}" ]]
}

gitignore_global_secrets_available() {
    declare -p SECRET_GIT_IGNORE_GLOBAL_ENTRIES &>/dev/null || return 1
    [[ ${#SECRET_GIT_IGNORE_GLOBAL_ENTRIES[@]} -gt 0 ]]
}

git_identity_matches_secrets() {
    [[ "$(git config --global user.name 2>/dev/null || true)" == "$SECRET_GIT_USER_NAME" ]] || return 1
    [[ "$(git config --global user.email 2>/dev/null || true)" == "$SECRET_GIT_USER_EMAIL" ]]
}

apply_git_identity_from_secrets() {
    git config --global user.name "$SECRET_GIT_USER_NAME"
    git config --global user.email "$SECRET_GIT_USER_EMAIL"
}

git_default_branch_is_main() {
    [[ "$(git config --global init.defaultBranch 2>/dev/null || true)" == "main" ]]
}

set_git_default_branch_main() {
    git config --global init.defaultBranch main
}

GIT_CUSTOM_STEPS=(
    "Set Git default branch to main|set_git_default_branch_main|git_default_branch_is_main|optional"
)

GIT_CONDITIONAL_STEPS=(
    "Configure Git identity"
    "Configure global Git ignore file"
)

GIT_SECTION_TOTAL=$(( \
    $(declared_array_length "GIT_CONDITIONAL_STEPS") + \
    $(declared_array_length "GIT_CUSTOM_STEPS") \
))

section_start "Git Settings" "$GIT_SECTION_TOTAL"

if git_identity_secrets_available; then
    run_step \
        "Configure Git identity" \
        "apply_git_identity_from_secrets" \
        "git_identity_matches_secrets" \
        "optional"
else
    run_skipped_step \
        "Configure Git identity" \
        "Missing config/secrets.sh Git identity values"
fi

gitignore_global_is_configured() {
    local entry
    local -n entries="SECRET_GIT_IGNORE_GLOBAL_ENTRIES"

    [[ -f "$GIT_IGNORE_GLOBAL_FILE" ]] || return 1

    for entry in "${entries[@]}"; do
        grep -Fxq "$entry" "$GIT_IGNORE_GLOBAL_FILE" || return 1
    done

    [[ "$(git config --global core.excludesfile 2>/dev/null || true)" == "$GIT_IGNORE_GLOBAL_FILE" ]]
}

ensure_gitignore_global() {
    local entry
    local -n entries="SECRET_GIT_IGNORE_GLOBAL_ENTRIES"

    if [[ -f "$GIT_IGNORE_GLOBAL_FILE" ]]; then
        backup_file "$GIT_IGNORE_GLOBAL_FILE"
    fi

    touch "$GIT_IGNORE_GLOBAL_FILE"

    for entry in "${entries[@]}"; do
        if ! grep -Fxq "$entry" "$GIT_IGNORE_GLOBAL_FILE"; then
            printf '%s\n' "$entry" >> "$GIT_IGNORE_GLOBAL_FILE"
        fi
    done

    git config --global core.excludesfile "$GIT_IGNORE_GLOBAL_FILE"
}

if gitignore_global_secrets_available; then
    run_step \
        "Configure global Git ignore file" \
        "ensure_gitignore_global" \
        "gitignore_global_is_configured" \
        "optional"
else
    run_skipped_step \
        "Configure global Git ignore file" \
        "Missing config/secrets.sh Git ignore entries"
fi

run_custom_steps_from_entries "GIT_CUSTOM_STEPS"

section_end "Git Settings"
