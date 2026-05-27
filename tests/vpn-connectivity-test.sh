#!/bin/bash

################################################################################
# Ymmo VPN Connectivity Test Suite
# Purpose: Validate IPSec tunnels, routing, and failover mechanisms
# Author: Titouan (Lead INFRA)
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASS=0
FAIL=0
WARN=0

log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARN++)); }

################################################################################
# Test Cases
################################################################################

test_hq_reachable() {
    log_test "HQ Firewall reachable (10.0.0.254)"

    if ping -c 1 -W 2 10.0.0.254 &> /dev/null; then
        log_pass "HQ Firewall responds to ICMP"
    else
        log_fail "Cannot reach HQ Firewall (10.0.0.254)"
    fi
}

test_vpn_tunnel_status() {
    log_test "VPN Tunnel status"

    if command -v ipsec &> /dev/null; then
        tunnels=$(ipsec status 2>/dev/null | grep -c "established" || echo 0)
        if [ "$tunnels" -gt 0 ]; then
            log_pass "Found $tunnels active IPSec tunnel(s)"
        else
            log_warn "No active IPSec tunnels (may be normal if tunnel not initiated)"
        fi
    else
        log_warn "Strongswan not installed, skipping tunnel check"
    fi
}

test_ad_dns_resolution() {
    log_test "AD/DNS resolution for ymmo.local domain"

    if nslookup ymmo.local 10.0.0.1 &> /dev/null; then
        log_pass "DNS resolves ymmo.local via AD server (10.0.0.1)"
    else
        log_fail "Cannot resolve ymmo.local from AD server"
    fi
}

test_dhcp_functionality() {
    log_test "DHCP server reachability (10.0.0.1)"

    if timeout 2 bash -c "echo > /dev/tcp/10.0.0.1/67" 2>/dev/null; then
        log_pass "DHCP server listening on 10.0.0.1:67"
    else
        log_warn "DHCP port not responding (may require UDP test)"
    fi
}

test_branch_connectivity() {
    log_test "Branch office connectivity (sampling 10.0.1.0/24)"

    if ping -c 1 -W 2 10.0.1.254 &> /dev/null; then
        log_pass "Branch 1 gateway reachable (10.0.1.254)"
    else
        log_fail "Cannot reach Branch 1 gateway (10.0.1.254)"
    fi
}

test_web_server() {
    log_test "Web server accessibility (10.0.0.2:80)"

    if timeout 3 curl -s -f http://10.0.0.2:80 &> /dev/null; then
        log_pass "Web server responding on 10.0.0.2:80"
    else
        log_warn "Web server not responding (may not be deployed yet)"
    fi
}

test_database_connectivity() {
    log_test "Database connectivity (10.0.0.2:5432)"

    if timeout 2 bash -c "echo > /dev/tcp/10.0.0.2/5432" 2>/dev/null; then
        log_pass "Database port open on 10.0.0.2:5432"
    else
        log_warn "Database port not responding (may not be deployed)"
    fi
}

test_route_table() {
    log_test "Route table configuration"

    local has_vpn_route=0
    if ip route | grep -q "10.0\." ; then
        log_pass "VPN routes present in routing table"
        has_vpn_route=1
    else
        log_fail "Missing VPN routes in routing table"
    fi

    # Show routes
    echo "Current routes to 10.0.0.0/8:"
    ip route | grep "10.0\." || echo "  (none found)"
}

test_firewall_rules() {
    log_test "Firewall rules (IPSec ports)"

    # Check UFW status
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            log_pass "UFW firewall is active"

            # Check specific rules
            if ufw status | grep -q "500.*ALLOW"; then
                log_pass "IPSec IKE port (500/UDP) allowed"
            else
                log_fail "IPSec IKE port (500/UDP) not allowed"
            fi
        else
            log_warn "UFW firewall not enabled"
        fi
    else
        log_warn "UFW not installed"
    fi
}

test_vpn_failover() {
    log_test "VPN failover scenario (simulated)"

    log_warn "Failover test: Manual intervention required"
    echo "  To test failover:"
    echo "  1. Kill IPSec: systemctl stop strongswan"
    echo "  2. Measure downtime"
    echo "  3. Restart: systemctl start strongswan"
    echo "  4. Verify tunnel re-establishes within 30s"
}

test_bandwidth_saturation() {
    log_test "Network bandwidth test (basic)"

    if command -v iperf3 &> /dev/null; then
        log_warn "iperf3 found - manual test required:"
        echo "  iperf3 -s -B 10.0.0.254 (on HQ)"
        echo "  iperf3 -c 10.0.0.254 -t 10 -R (on Branch)"
    else
        log_warn "iperf3 not installed - skipping bandwidth test"
    fi
}

test_latency() {
    log_test "VPN tunnel latency (10.0.1.254)"

    if command -v mtr &> /dev/null; then
        avg_latency=$(mtr -c 10 -n 10.0.1.254 2>/dev/null | tail -1 | awk '{print $4}' || echo "unknown")
        if [ "$avg_latency" != "unknown" ]; then
            log_pass "Average latency to Branch 1: ${avg_latency}ms"
        fi
    else
        log_warn "mtr not installed - using ping for latency estimate"
        ping -c 5 -W 2 10.0.1.254 | tail -1
    fi
}

################################################################################
# Test Reporting
################################################################################

show_summary() {
    echo ""
    echo "========================================="
    echo "VPN Connectivity Test Report"
    echo "========================================="
    echo -e "${GREEN}Passed: ${PASS}${NC}"
    echo -e "${RED}Failed: ${FAIL}${NC}"
    echo -e "${YELLOW}Warnings: ${WARN}${NC}"
    echo "========================================="

    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}✓ All critical tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Review above.${NC}"
        return 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    echo "========================================="
    echo "Ymmo VPN Connectivity Test Suite"
    echo "Time: $(date)"
    echo "========================================="
    echo ""

    # Run all tests
    test_hq_reachable
    test_vpn_tunnel_status
    test_ad_dns_resolution
    test_dhcp_functionality
    test_branch_connectivity
    test_web_server
    test_database_connectivity
    test_route_table
    test_firewall_rules
    test_vpn_failover
    test_bandwidth_saturation
    test_latency

    # Show summary
    show_summary
}

main "$@"
