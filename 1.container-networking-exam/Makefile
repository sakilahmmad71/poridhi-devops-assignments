.PHONY: run
setup:
	@echo "Running the program..."

	@echo "Create Isolated network namespaces"
	ip netns add ns1
	ip netns add ns2
	ip netns add router-ns

	@echo "Create bridge interfaces"
	ip link add br1 type bridge
	ip link add br2 type bridge

	@echo "Create veth cables for ns1 and ns2"
	ip link add veth-ns1 type veth peer name veth-br1
	ip link add veth-ns2 type veth peer name veth-br2

	@echo "Create veth cables for router-ns"
	ip link add veth-router1 type veth peer name veth-br1-router
	ip link add veth-router2 type veth peer name veth-br2-router

	@echo "Assign veth cables to network namespaces"
	ip link set veth-ns1 netns ns1
	ip link set veth-ns2 netns ns2
	ip link set veth-router1 netns router-ns
	ip link set veth-router2 netns router-ns

	@echo "Attach veth cables to bridges"
	ip link set veth-br1 master br1
	ip link set veth-br2 master br2
	ip link set veth-br1-router master br1
	ip link set veth-br2-router master br2

	@echo "Set veth cables up in namespaces"
	ip netns exec ns1 ip link set veth-ns1 up
	ip netns exec ns2 ip link set veth-ns2 up
	ip netns exec router-ns ip link set veth-router1 up
	ip netns exec router-ns ip link set veth-router2 up

	@echo "Set bridge interfaces up"
	ip link set veth-br1 up
	ip link set veth-br2 up
	ip link set veth-br1-router up
	ip link set veth-br2-router up
	ip link set br1 up
	ip link set br2 up

	@echo "Assign IP addresses to bridge interfaces"
	ip addr add 192.168.0.1/24 dev br1
	ip addr add 192.168.1.1/24 dev br2

	@echo "Assign IP addresses to network namespaces"
	ip netns exec ns1 ip addr add 192.168.0.2/24 dev veth-ns1
	ip netns exec ns2 ip addr add 192.168.1.2/24 dev veth-ns2
	ip netns exec router-ns ip addr add 192.168.0.254/24 dev veth-router1
	ip netns exec router-ns ip addr add 192.168.1.254/24 dev veth-router2

	@echo "Set default route in ns1 and ns2"
	ip netns exec ns1 ip route add default via 192.168.0.254 dev veth-ns1
	ip netns exec ns2 ip route add default via 192.168.1.254 dev veth-ns2

	@echo "Enable IP forwarding in router-ns"
	ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

	@echo "Set up NAT or forwarding rules"
	ip netns exec router-ns iptables -t nat -A POSTROUTING -o veth-router2 -j MASQUERADE
	ip netns exec router-ns iptables -A FORWARD -i veth-router1 -o veth-router2 -j ACCEPT
	ip netns exec router-ns iptables -A FORWARD -i veth-router2 -o veth-router1 -j ACCEPT

	@echo "Show IP addresses and routing tables"
	ip netns exec ns1 ip addr show dev veth-ns1
	ip netns exec ns2 ip addr show dev veth-ns2
	ip netns exec router-ns ip addr show
	ip netns exec router-ns ip route show

	@echo "Show bridge interfaces"
	ip addr show dev br1
	ip addr show dev br2

.PHONY: run
test:
	@echo "Testing the program..."
	@echo "Ping from ns1 to ns2"
	ip netns exec ns1 ping -c 4 192.168.1.2 
	@echo "Ping from ns2 to ns1"
	ip netns exec ns2 ping -c 4 192.168.0.2
	@echo "Ping from ns1 to router-ns"
	ip netns exec ns1 ping -c 4 192.168.0.254
	@echo "Ping from ns2 to router-ns"
	ip netns exec ns2 ping -c 4 192.168.1.254

.PHONY: run
clean:
	@echo "Cleaning up network namespaces and interfaces..."
	@ip netns del ns1
	@ip netns del ns2
	@ip netns del router-ns
	@ip link del br1
	@ip link del br2
