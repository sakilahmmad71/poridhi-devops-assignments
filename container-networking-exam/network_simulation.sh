#!/bin/bash

set -e  # Exit on any error

echo "Creating network namespaces (ns1, ns2, router-ns)"
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add router-ns

echo "Creating network bridges (br0, br1)"
sudo ip link add br0 type bridge
sudo ip link add br1 type bridge
sudo ip link set br0 up
sudo ip link set br1 up

echo "Creating virtual Ethernet (veth) pairs (veth1, veth2, veth-r1, veth-r2)"
sudo ip link add veth1 type veth peer name veth1-br
sudo ip link add veth2 type veth peer name veth2-br
sudo ip link add veth-r1 type veth peer name veth-r1-br
sudo ip link add veth-r2 type veth peer name veth-r2-br

echo "Assigning interfaces to network namespaces with veth pairs (veth1, veth2, veth-r1, veth-r2)"
sudo ip link set veth1 netns ns1
sudo ip link set veth2 netns ns2
sudo ip link set veth-r1 netns router-ns
sudo ip link set veth-r2 netns router-ns

echo "Connecting veth pairs to bridges with br0 and br1"
sudo ip link set veth1-br master br0
sudo ip link set veth2-br master br1
sudo ip link set veth-r1-br master br0
sudo ip link set veth-r2-br master br1

echo "Bringing up veth interfaces and bridges"
sudo ip netns exec ns1 ip link set veth1 up
sudo ip netns exec ns2 ip link set veth2 up
sudo ip netns exec router-ns ip link set veth-r1 up
sudo ip netns exec router-ns ip link set veth-r2 up
sudo ip link set veth1-br up
sudo ip link set veth2-br up
sudo ip link set veth-r1-br up
sudo ip link set veth-r2-br up

echo "Assigning IP addresses to interfaces in network namespaces (ns1, ns2, router-ns)"
sudo ip netns exec ns1 ip addr add 192.168.1.2/24 dev veth1
sudo ip netns exec ns2 ip addr add 192.168.2.2/24 dev veth2
sudo ip netns exec router-ns ip addr add 192.168.1.1/24 dev veth-r1
sudo ip netns exec router-ns ip addr add 192.168.2.1/24 dev veth-r2

echo "Setting up routing in router-ns"
sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec ns1 ip route add default via 192.168.1.1
sudo ip netns exec ns2 ip route add default via 192.168.2.1

echo "Testing connectivity between network namespaces"
sudo ip netns exec ns1 ping -c 3 192.168.1.1
sudo ip netns exec ns2 ping -c 3 192.168.2.1
sudo ip netns exec ns1 ping -c 3 192.168.2.2

echo "✅ Network setup complete!"