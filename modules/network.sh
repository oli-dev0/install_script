#!/usr/bin/env bash
# shellcheck disable=SC2034

NETWORK_DNS_SETTINGS_SOURCE="$ROOT_DIR/config/network/dns.sh"

NETWORK_CONDITIONAL_STEPS=(
    "Restore saved Wi-Fi profiles"
)

NETWORK_CUSTOM_STEPS=(
    "Set DNS for saved LAN and Wi-Fi profiles|apply_wifi_lan_dns|wifi_lan_dns_is_configured|optional"
)

NETWORK_SECTION_TOTAL=$(( \
    $(declared_array_length "NETWORK_CONDITIONAL_STEPS") + \
    $(declared_array_length "NETWORK_CUSTOM_STEPS") \
))

section_start "Network Settings" "$NETWORK_SECTION_TOTAL"

# shellcheck source=config/network/dns.sh
source "$NETWORK_DNS_SETTINGS_SOURCE"

network_wifi_secrets_available() {
    declare -p SECRET_NETWORK_WIFI_PROFILES &>/dev/null || return 1
    [[ ${#SECRET_NETWORK_WIFI_PROFILES[@]} -gt 0 ]]
}

network_is_managed_type() {
    local connection_type="$1"

    [[ "$connection_type" == "802-11-wireless" || "$connection_type" == "802-3-ethernet" ]]
}

normalize_nmcli_value() {
    local value="$1"

    printf '%s\n' "${value//\\/}"
}

wifi_profile_matches_secret() {
    local connection_name="$1"
    local expected_ssid="$2"
    local expected_password="$3"
    local actual_ssid=""
    local actual_password=""

    actual_ssid="$(nmcli -s --show-secrets -g 802-11-wireless.ssid connection show "$connection_name" 2>/dev/null || true)"
    actual_password="$(nmcli -s --show-secrets -g 802-11-wireless-security.psk connection show "$connection_name" 2>/dev/null || true)"

    [[ "$actual_ssid" == "$expected_ssid" ]] || return 1
    [[ "$actual_password" == "$expected_password" ]]
}

saved_wifi_profiles_are_restored() {
    local entry
    local connection_name ssid password

    network_wifi_secrets_available || return 1

    for entry in "${SECRET_NETWORK_WIFI_PROFILES[@]}"; do
        IFS='|' read -r connection_name ssid password <<< "$entry"
        wifi_profile_matches_secret "$connection_name" "$ssid" "$password" || return 1
    done
}

apply_saved_wifi_profiles() {
    local entry
    local connection_name ssid password

    for entry in "${SECRET_NETWORK_WIFI_PROFILES[@]}"; do
        IFS='|' read -r connection_name ssid password <<< "$entry"

        if ! nmcli -t -f NAME connection show | grep -Fxq "$connection_name"; then
            nmcli connection add type wifi con-name "$connection_name" ifname "*" ssid "$ssid"
        fi

        nmcli connection modify "$connection_name" connection.autoconnect yes 802-11-wireless.ssid "$ssid"

        if [[ -n "$password" ]]; then
            nmcli connection modify \
                "$connection_name" \
                802-11-wireless-security.key-mgmt wpa-psk \
                802-11-wireless-security.psk "$password"
        fi
    done
}

connection_dns_is_configured() {
    local connection_name="$1"
    local actual_ipv4_dns=""
    local actual_ipv4_ignore=""
    local actual_ipv6_dns=""
    local actual_ipv6_ignore=""

    actual_ipv4_dns="$(nmcli -g ipv4.dns connection show "$connection_name" 2>/dev/null || true)"
    actual_ipv4_ignore="$(nmcli -g ipv4.ignore-auto-dns connection show "$connection_name" 2>/dev/null || true)"
    actual_ipv6_dns="$(nmcli -g ipv6.dns connection show "$connection_name" 2>/dev/null || true)"
    actual_ipv6_ignore="$(nmcli -g ipv6.ignore-auto-dns connection show "$connection_name" 2>/dev/null || true)"

    [[ "$actual_ipv4_dns" == "$NETWORK_DNS_IPV4" ]] || return 1
    [[ "$actual_ipv4_ignore" == "yes" ]] || return 1
    [[ "$(normalize_nmcli_value "$actual_ipv6_dns")" == "$NETWORK_DNS_IPV6" ]] || return 1
    [[ "$actual_ipv6_ignore" == "yes" ]] || return 1
}

wifi_lan_dns_is_configured() {
    local line
    local connection_name connection_type

    while IFS= read -r line; do
        IFS=':' read -r connection_name connection_type <<< "$line"
        network_is_managed_type "$connection_type" || continue
        connection_dns_is_configured "$connection_name" || return 1
    done < <(nmcli -t -f NAME,TYPE connection show)
}

apply_connection_dns() {
    local connection_name="$1"

    nmcli connection modify \
        "$connection_name" \
        ipv4.ignore-auto-dns yes \
        ipv4.dns "$NETWORK_DNS_IPV4" \
        ipv6.ignore-auto-dns yes \
        ipv6.dns "$NETWORK_DNS_IPV6"
}

apply_wifi_lan_dns() {
    local line
    local connection_name connection_type

    while IFS= read -r line; do
        IFS=':' read -r connection_name connection_type <<< "$line"
        network_is_managed_type "$connection_type" || continue
        apply_connection_dns "$connection_name"
    done < <(nmcli -t -f NAME,TYPE connection show)
}

if network_wifi_secrets_available; then
    run_step \
        "Restore saved Wi-Fi profiles" \
        "apply_saved_wifi_profiles" \
        "saved_wifi_profiles_are_restored" \
        "optional"
else
    run_skipped_step \
        "Restore saved Wi-Fi profiles" \
        "Missing config/secrets.sh Wi-Fi profile data"
fi

run_custom_steps_from_entries "NETWORK_CUSTOM_STEPS"

section_end "Network Settings"
