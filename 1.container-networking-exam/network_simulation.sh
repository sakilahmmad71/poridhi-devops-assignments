#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print status messages
print_status() {
	echo -e "${GREEN}[STATUS]${NC} $1"
}

# Function to print test results
print_test() {
	echo -e "${YELLOW}[TEST]${NC} $1"
}

# Function to print errors
print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Function to perform cleanup
cleanup() {
	print_status "Cleaning up network configuration..."
	sudo ip netns delete ns1 2>/dev/null || true
	sudo ip netns delete ns2 2>/dev/null || true
	sudo ip netns delete router-ns 2>/dev/null || true
	sudo ip link delete br0 2>/dev/null || true
	sudo ip link delete br1 2>/dev/null || true
}

# Function to test connectivity between namespaces
test_connectivity() {
	local from_ns=$1
	local to_ip=$2
	local description=$3
	
	print_test "Testing connectivity: $description"
	if sudo ip netns exec $from_ns ping -c 2 -W 1 $to_ip > /dev/null 2>&1; then
		echo -e "${GREEN}✓ Success: $from_ns can reach $to_ip${NC}"
		return 0
	else
		echo -e "${RED}✗ Failed: $from_ns cannot reach $to_ip${NC}"
		return 1
	fi
}

# Function to show network configuration
show_network_config() {
	local ns=$1
	echo -e "\n${YELLOW}Network configuration for $ns:${NC}"
	echo "Interfaces:"
	sudo ip netns exec $ns ip addr show
	echo "Routes:"
	sudo ip netns exec $ns ip route show
}

# Main setup function
setup_network() {
	print_status "Setting up network environment..."
	
	# Create namespaces
	print_status "Creating network namespaces..."
	sudo ip netns add ns1
	sudo ip netns add ns2
	sudo ip netns add router-ns
	
	# Create veth pairs
	print_status "Creating veth pairs..."
	sudo ip link add veth1 type veth peer name veth1-router
	sudo ip link add veth2 type veth peer name veth2-router
	
	# Setup ns1
	print_status "Configuring ns1..."
	sudo ip link set veth1 netns ns1
	sudo ip link set veth1-router netns router-ns
	sudo ip netns exec ns1 ip link set lo up
	sudo ip netns exec ns1 ip link set veth1 up
	sudo ip netns exec ns1 ip addr add 192.168.1.2/24 dev veth1
	
	# Setup ns2
	print_status "Configuring ns2..."
	sudo ip link set veth2 netns ns2
	sudo ip link set veth2-router netns router-ns
	sudo ip netns exec ns2 ip link set lo up
	sudo ip netns exec ns2 ip link set veth2 up
	sudo ip netns exec ns2 ip addr add 192.168.2.2/24 dev veth2
	
	# Setup router
	print_status "Configuring router..."
	sudo ip netns exec router-ns ip link set lo up
	sudo ip netns exec router-ns ip link set veth1-router up
	sudo ip netns exec router-ns ip link set veth2-router up
	sudo ip netns exec router-ns ip addr add 192.168.1.1/24 dev veth1-router
	sudo ip netns exec router-ns ip addr add 192.168.2.1/24 dev veth2-router
	
	# Enable IP forwarding
	print_status "Enabling IP forwarding..."
	sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1
	
	# Configure routing
	print_status "Configuring routing..."
	sudo ip netns exec ns1 ip route add default via 192.168.1.1
	sudo ip netns exec ns2 ip route add default via 192.168.2.1
	
	# Configure iptables
	print_status "Configuring iptables..."
	sudo ip netns exec router-ns iptables -F
	sudo ip netns exec router-ns iptables -t nat -F
	sudo ip netns exec router-ns iptables -P FORWARD ACCEPT
	sudo ip netns exec router-ns iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o veth2-router -j MASQUERADE
	sudo ip netns exec router-ns iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o veth1-router -j MASQUERADE
}

# Function to run comprehensive tests
run_tests() {
	print_status "Running network tests..."
	
	# Show network configuration
	show_network_config "ns1"
	show_network_config "ns2"
	show_network_config "router-ns"
	
	# Test basic connectivity
	test_connectivity "ns1" "192.168.1.1" "ns1 -> router (direct)"
	test_connectivity "ns2" "192.168.2.1" "ns2 -> router (direct)"
	
	# Test cross-network connectivity
	test_connectivity "ns1" "192.168.2.2" "ns1 -> ns2 (cross-network)"
	test_connectivity "ns2" "192.168.1.2" "ns2 -> ns1 (cross-network)"
	
	# Test router connectivity
	test_connectivity "router-ns" "192.168.1.2" "router -> ns1"
	test_connectivity "router-ns" "192.168.2.2" "router -> ns2"
	
	# Show ARP tables
	print_status "Displaying ARP tables..."
	echo -e "\nNS1 ARP table:"
	sudo ip netns exec ns1 ip neigh show
	echo -e "\nNS2 ARP table:"
	sudo ip netns exec ns2 ip neigh show
	echo -e "\nRouter ARP table:"
	sudo ip netns exec router-ns ip neigh show
}

# Main script execution
case "${1:-}" in
	"clean")
		cleanup
		;;
	"test")
		run_tests
		;;
	"setup")
		cleanup
		setup_network
		;;
	*)
		print_status "Setting up network and running tests..."
		cleanup
		setup_network
		run_tests
		;;
esac

print_status "Done!"
