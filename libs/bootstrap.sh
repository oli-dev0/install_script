#!/usr/bin/env bash

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"

source_required_file() {
    local file_path="$1"
    local label="${2:-required file}"

    if [[ ! -f "$file_path" ]]; then
        echo "Missing $label: $file_path" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$file_path"
}

source_optional_file() {
    local file_path="$1"

    if [[ -f "$file_path" ]]; then
        # shellcheck source=/dev/null
        source "$file_path"
    fi
}

source_required_file "$ROOT_DIR/libs/styles.sh" "core library"
source_required_file "$ROOT_DIR/libs/logging.sh" "core library"
source_required_file "$ROOT_DIR/libs/prompts.sh" "core library"
source_required_file "$ROOT_DIR/libs/system.sh" "core library"
source_required_file "$ROOT_DIR/libs/settings.sh" "core library"
source_required_file "$ROOT_DIR/libs/summary.sh" "core library"
source_required_file "$ROOT_DIR/libs/steps.sh" "core library"

DRY_RUN=false
YES_MODE=false
ONLY_SECTION=""

CONFIG_FILE="$ROOT_DIR/config/config.sh"
SECRETS_FILE="$ROOT_DIR/config/secrets.sh"
LOG_FILE=""
BACKUP_RUN_DIR=""

SECTIONS=(
    "display|Display Settings|modules/display.sh"
    "network|Network Settings|modules/network.sh"
    "apps|Application Installs|modules/apps.sh"
    "terminal|Terminal Settings|modules/terminal.sh"
    "git|Git Settings|modules/git.sh"
    "system|System Settings|modules/system.sh"
)

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes|-y)
                YES_MODE=true
                shift
                ;;
            --only)
                ONLY_SECTION="${2:-}"
                if [[ -z "$ONLY_SECTION" ]]; then
                    echo "Error: --only requires a section name"
                    exit 1
                fi
                shift 2
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

print_help() {
    cat <<'EOF'
Linux Mint Bootstrap

Usage:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --only apps
  ./install.sh --yes

Options:
  --dry-run       Show what would run without making changes
  --only NAME     Run only one section
  --yes, -y       Automatically answer yes to prompts
  --help, -h      Show help

EOF

    print_section_help
}

print_section_help() {
    local section
    local section_name section_title module_path

    echo "Sections:"
    for section in "${SECTIONS[@]}"; do
        IFS='|' read -r section_name section_title module_path <<< "$section"
        printf '  %s\n' "$section_name"
    done
}

validate_only_section() {
    local section

    if [[ -z "$ONLY_SECTION" ]]; then
        return 0
    fi

    local section_name section_title module_path

    for section in "${SECTIONS[@]}"; do
        IFS='|' read -r section_name section_title module_path <<< "$section"
        if [[ "$ONLY_SECTION" == "$section_name" ]]; then
            return 0
        fi
    done

    echo "Error: unknown section '$ONLY_SECTION'"
    echo "Run './install.sh --help' to see supported sections."
    exit 1
}

init_runtime_directories() {
    mkdir -p "$ROOT_DIR/logs"
    mkdir -p "$ROOT_DIR/backups"
}

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Missing config file: $CONFIG_FILE"
        exit 1
    fi

    source_required_file "$CONFIG_FILE" "config file"
    source_optional_file "$SECRETS_FILE"
}

print_app_header() {
    echo -e "${BOLD}${CYAN}"
    echo "========================================"
    echo "        Linux Mint Bootstrap"
    echo "========================================"
    echo -e "${RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Mode: dry-run${RESET}"
    fi

    if [[ -n "$ONLY_SECTION" ]]; then
        echo -e "${YELLOW}Only section: $ONLY_SECTION${RESET}"
    fi

    echo
}

run_section() {
    local section_name="$1"
    local section_title="$2"
    local module_path="$3"

    if [[ -n "$ONLY_SECTION" && "$ONLY_SECTION" != "$section_name" ]]; then
        log_info "Skipping section due to --only: $section_name"
        return 0
    fi

    echo
    echo -e "${BOLD}${BLUE}Next section: $section_title${RESET}"

    if ! ask_yes_no "Do you want to start $section_title?" "y"; then
        echo -e "${YELLOW}${ICON_SKIP} Skipped $section_title${RESET}"
        log_skipped "Section skipped: $section_title"
        increment_skipped
        return 0
    fi

    if [[ ! -f "$module_path" ]]; then
        echo -e "${RED}${ICON_ERROR} Missing section module: $module_path${RESET}"
        log_error "Missing section module: $module_path"
        exit 1
    fi

    source_required_file "$module_path" "section module"
}

run_all_sections() {
    local section
    local section_name section_title module_path

    for section in "${SECTIONS[@]}"; do
        IFS='|' read -r section_name section_title module_path <<< "$section"
        run_section "$section_name" "$section_title" "$ROOT_DIR/$module_path"
    done
}
