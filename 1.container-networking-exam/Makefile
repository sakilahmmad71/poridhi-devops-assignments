# Color codes for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Function to print status messages
print_status = @echo -e "$(GREEN)[STATUS]$(NC) $$1"

# Function to print test results
print_test = @echo -e "$(YELLOW)[TEST]$(NC) $$1"

# Function to print errors
print_error = @echo -e "$(RED)[ERROR]$(NC) $$1"

# Default target
.PHONY: all
all: setup test

# Setup target
.PHONY: setup
setup: clean
	$(call print_status, "Setting up network environment...")
	$(call print_status, "Creating network namespaces...")
	sudo ip netns add ns1
	sudo ip netns add ns2
	sudo ip netns add router-ns
	$(call print_status, "Creating veth pairs...")
	sudo ip link add veth1 type veth peer name veth1-router
	sudo ip link add veth2 type veth peer name veth2-router
	$(call print_status, "Configuring ns1...")
	sudo ip link set veth1 netns ns1
	sudo ip link set veth1-router netns router-ns
	sudo ip netns exec ns1 ip link set lo up
	sudo ip netns exec ns1 ip link set veth1 up
	sudo ip netns exec ns1 ip addr add 192.168.1.2/24 dev veth1
	$(call print_status, "Configuring ns2...")
	sudo ip link set veth2 netns ns2
	sudo ip link set veth2-router netns router-ns
	sudo ip netns exec ns2 ip link set lo up
	sudo ip netns exec ns2 ip link set veth2 up
	sudo ip netns exec ns2 ip addr add 192.168.2.2/24 dev veth2
	$(call print_status, "Configuring router...")
	sudo ip netns exec router-ns ip link set lo up
	sudo ip netns exec router-ns ip link set veth1-router up
	sudo ip netns exec router-ns ip link set veth2-router up
	sudo ip netns exec router-ns ip addr add 192.168.1.1/24 dev veth1-router
	sudo ip netns exec router-ns ip addr add 192.168.2.1/24 dev veth2-router
	$(call print_status, "Enabling IP forwarding...")
	sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1
	$(call print_status, "Configuring routing...")
	sudo ip netns exec ns1 ip route add default via 192.168.1.1
	sudo ip netns exec ns2 ip route add default via 192.168.2.1
	$(call print_status, "Configuring iptables...")
	sudo ip netns exec router-ns iptables -F
	sudo ip netns exec router-ns iptables -t nat -F
	sudo ip netns exec router-ns iptables -P FORWARD ACCEPT
	sudo ip netns exec router-ns iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o veth2-router -j MASQUERADE
	sudo ip netns exec router-ns iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o veth1-router -j MASQUERADE

# Test target
.PHONY: test
test:
	$(call print_status, "Running network tests...")
	$(call show_network_config, "ns1")
	$(call show_network_config, "ns2")
	$(call show_network_config, "router-ns")
	$(call test_connectivity, "ns1", "192.168.1.1", "ns1 -> router (direct)")
	$(call test_connectivity, "ns2", "192.168.2.1", "ns2 -> router (direct)")
	$(call test_connectivity, "ns1", "192.168.2.2", "ns1 -> ns2 (cross-network)")
	$(call test_connectivity, "ns2", "192.168.1.2", "ns2 -> ns1 (cross-network)")
	$(call test_connectivity, "router-ns", "192.168.1.2", "router -> ns1")
	$(call test_connectivity, "router-ns", "192.168.2.2", "router -> ns2")
	$(call print_status, "Displaying ARP tables...")
	@echo -e "\nNS1 ARP table:"
	sudo ip netns exec ns1 ip neigh show
	@echo -e "\nNS2 ARP table:"
	sudo ip netns exec ns2 ip neigh show
	@echo -e "\nRouter ARP table:"
	sudo ip netns exec router-ns ip neigh show

# Clean target
.PHONY: clean
clean:
	$(call print_status, "Cleaning up network configuration...")
	sudo ip netns delete ns1 2>/dev/null || true
	sudo ip netns delete ns2 2>/dev/null || true
	sudo ip netns delete router-ns 2>/dev/null || true
	sudo ip link delete br0 2>/dev/null || true
	sudo ip link delete br1 2>/dev/null || true

# Help target
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Setup the network and run tests"
	@echo "  setup   - Setup the network"
	@echo "  test    - Run network tests"
	@echo "  clean   - Clean up the network configuration"
	@echo "  help    - Display this help message"

# Function to show network configuration
define show_network_config
	@echo -e "\n$(YELLOW)Network configuration for $$1:$(NC)"
	@echo "Interfaces:"
	sudo ip netns exec $$1 ip addr show
	@echo "Routes:"
	sudo ip netns exec $$1 ip route show
endef

# Function to test connectivity between namespaces
define test_connectivity
	$(call print_test, "Testing connectivity: $$3")
	if sudo ip netns exec $$1 ping -c 2 -W 1 $$2 > /dev/null 2>&1; then \
		echo -e "$(GREEN)✓ Success: $$1 can reach $$2$(NC)"; \
		return 0; \
	else \
		echo -e "$(RED)✗ Failed: $$1 cannot reach $$2$(NC)"; \
		return 1; \
	fi
endef
