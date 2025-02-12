# Network Simulation Setup

This project sets up a network simulation using Linux network namespaces, bridges, and routing. The setup includes two isolated networks connected via a router namespace.
The network stack can be seen through https://excalidraw.com/#json=wL53YExhBXzrfFD596Fc7,Oy90N2phcutbGb0MyTqvPA

## Prerequisites

Ensure you have `iproute2` installed, as it is required to manage network namespaces and bridges.

```bash
sudo apt install iproute2 -y
```

## Usage

### Using the Bash Script

A script `network_simulation.sh` is provided for setting up the network.

#### Run the script

```bash
chmod +x network_simulation.sh
sudo ./network_simulation.sh setup
```

#### Test

To test all configurations:

```bash
sudo ./network_simulation.sh test
```

#### Cleanup

To remove all configurations:

````bash
sudo ./network_simulation.sh clean

### Using the Makefile

A `Makefile` is included to automate setup and cleanup.

#### Setup the network

```bash
sudo make setup
````

#### Test connectivity

```bash
sudo make test
```

#### Cleanup the network

```bash
sudo make clean
```

## Network Topology

- **Namespaces:**
  - `ns1` - Connected to `br1`
  - `ns2` - Connected to `br2`
  - `router-ns` - Connects `br1` and `br2`
- **Bridges:**
  - `br1` connects `ns1` and the router
  - `br2` connects `ns2` and the router

## IP Address Scheme

- `ns1`: `192.168.1.2/24`
- `ns2`: `192.168.2.2/24`
- `router-ns`:
  - `br1` side: `192.168.1.1/24`
  - `br2` side: `192.168.2.1/24`

## Notes

- Running the script or Makefile requires `sudo` privileges.
- IP forwarding is enabled in `router-ns` to facilitate communication between `ns1` and `ns2`.
