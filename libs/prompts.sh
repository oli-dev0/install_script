#!/usr/bin/env bash

ask_yes_no() {
    local question="$1"
    local default_answer="${2:-y}"
    local answer
    local prompt

    if [[ "$YES_MODE" == true ]]; then
        log_info "YES_MODE: auto yes for question: $question"
        return 0
    fi

    while true; do
        if [[ "$default_answer" == "y" ]]; then
            prompt="[Y/n]"
        else
            prompt="[y/N]"
        fi

        read -r -p "$question $prompt " answer
        answer="${answer:-$default_answer}"

        case "${answer,,}" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                echo "Invalid answer. Use y or n."
                ;;
        esac
    done
}

ask_retry_continue_quit() {
    local criticality="$1"
    local answer

    if [[ "$YES_MODE" == true ]]; then
        if [[ "$criticality" == "critical" ]]; then
            log_error "YES_MODE: critical step failed, quitting"
            return 2
        fi

        log_warning "YES_MODE: optional step failed, continuing"
        return 1
    fi

    while true; do
        if [[ "$criticality" == "critical" ]]; then
            read -r -p "Retry or quit? [r/q] " answer

            case "${answer,,}" in
                r|retry)
                    return 0
                    ;;
                q|quit)
                    return 2
                    ;;
                *)
                    echo "Invalid answer. Use r or q."
                    ;;
            esac
        else
            read -r -p "Retry, continue, or quit? [r/c/q] " answer

            case "${answer,,}" in
                r|retry)
                    return 0
                    ;;
                c|continue)
                    return 1
                    ;;
                q|quit)
                    return 2
                    ;;
                *)
                    echo "Invalid answer. Use r, c, or q."
                    ;;
            esac
        fi
    done
}

ask_required_value() {
    local question="$1"
    local answer

    while true; do
        read -r -p "$question " answer

        if [[ -n "$answer" ]]; then
            printf '%s\n' "$answer"
            return 0
        fi

        echo "Value cannot be empty."
    done
}
