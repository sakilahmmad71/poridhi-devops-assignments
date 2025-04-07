import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";
import * as fs from "fs";

// Create a key-pair for SSH access
const keyPair = new aws.ec2.KeyPair("node-mysql-keypair", {
	keyName: "node-mysql-keypair",
	publicKey: "" // Replace with your public key
});

const vpc = new aws.ec2.Vpc("node-mysql-vpc", {
	cidrBlock: "10.0.0.0/16",
	enableDnsSupport: true,
	enableDnsHostnames: true,
	tags: {
		Name: "node-mysql-vpc",
	}
});

const publicSubnet = new aws.ec2.Subnet("node-public-subnet", {
	vpcId: vpc.id,
	cidrBlock: "10.0.1.0/24",
	mapPublicIpOnLaunch: true,
	availabilityZone: "ap-southeast-1a",
	tags: {
		Name: "node-mysql-public-subnet",
	},
});

const privateSubnet = new aws.ec2.Subnet("mysql-private-subnet", {
	vpcId: vpc.id,
	cidrBlock: "10.0.2.0/24",
	mapPublicIpOnLaunch: false,
	availabilityZone: "ap-southeast-1a",
	tags: {
		Name: "node-mysql-private-subnet",
	},
});

const internetGateway = new aws.ec2.InternetGateway("node-mysql-internet-gateway", {
	vpcId: vpc.id,
	tags: {
		Name: "node-mysql-internet-gateway",
	},
});

const elasticIp = new aws.ec2.Eip("node-mysql-elastic-ip", {
	vpc: true,
	tags: {
		Name: "node-mysql-elastic-ip",
	},
});

const natGateway = new aws.ec2.NatGateway("node-mysql-nat-gateway", {
	allocationId: elasticIp.id,
	subnetId: publicSubnet.id,
	tags: {
		Name: "node-mysql-nat-gateway",
	},
});

const publicRouteTable = new aws.ec2.RouteTable("node-mysql-public-route-table", {
	vpcId: vpc.id,
	routes: [
		{
			cidrBlock: "0.0.0.0/0",
			gatewayId: internetGateway.id,
		},
	],
	tags: {
		Name: "node-mysql-public-route-table",
	},
});

const publicRouteTableAssociation = new aws.ec2.RouteTableAssociation("node-mysql-public-route-table-association", {
	subnetId: publicSubnet.id,
	routeTableId: publicRouteTable.id,
});

const privateRouteTable = new aws.ec2.RouteTable("node-mysql-private-route-table", {
	vpcId: vpc.id,
	routes: [
		{
			cidrBlock: "0.0.0.0/0",
			natGatewayId: natGateway.id,
		},
	],
	tags: {
		Name: "node-mysql-private-route-table",
	},
});

const privateRouteTableAssociation = new aws.ec2.RouteTableAssociation("node-mysql-private-route-table-association", {
	subnetId: privateSubnet.id,
	routeTableId: privateRouteTable.id,
});

const nodejsSecurityGroup = new aws.ec2.SecurityGroup("node-security-group", {
	vpcId: vpc.id,
	description: "Allow HTTP and SSH",
	ingress: [
		{
			protocol: "tcp",
			fromPort: 22,
			toPort: 22,
			cidrBlocks: ["0.0.0.0/0"],
			description: "Allow SSH",
		},
		{
			protocol: "tcp",
			fromPort: 3000,
			toPort: 3000,
			cidrBlocks: ["0.0.0.0/0"],
			description: "Allow HTTP",
		}
	],
	egress: [
		{
			protocol: "-1",
			fromPort: 0,
			toPort: 0,
			cidrBlocks: ["0.0.0.0/0"],
			description: "Allow all outbound traffic",
		}
	],
	tags: {
		Name: "node-security-group",
	},
});

const mysqlSecurityGroup = new aws.ec2.SecurityGroup("mysql-security-group", {
	vpcId: vpc.id,
	description: "Allow MySQL",
	ingress: [
		{
			protocol: "tcp",
			fromPort: 22,
			toPort: 22,
			cidrBlocks: [publicSubnet.cidrBlock.apply(cidr => cidr || "")],
			description: "Allow SSH from public subnet",
		},
		{
			protocol: "tcp",
			fromPort: 3306,
			toPort: 3306,
			cidrBlocks: [publicSubnet.cidrBlock.apply(cidr => cidr || "")],
			description: "Allow MySQL from public subnet",
		},
	],
	egress: [
		{
			protocol: "-1",
			fromPort: 0,
			toPort: 0,
			cidrBlocks: ["0.0.0.0/0"],
			description: "Allow all outbound traffic",
		}
	],
	tags: {
		Name: "mysql-security-group",
	},
});

const mysqlSetupScript = fs.readFileSync("../mysql-setup.sh", "utf8");
console.log(mysqlSetupScript);

const mysqlInstance = new aws.ec2.Instance("mysql-ec2-instance", {
	ami: "ami-01811d4912b4ccb26", // Ubuntu AMI
	instanceType: "t2.micro",
	keyName: keyPair.keyName,
	vpcSecurityGroupIds: [mysqlSecurityGroup.id],
	subnetId: privateSubnet.id,
	tags: {
		Name: "mysql-ec2-instance",
	},
	userData: mysqlSetupScript,
});

const mysqlInstancePrivateIp = mysqlInstance.privateIp;
const nodejsSetupScript = fs.readFileSync("../nodejs-setup.sh", "utf8");
console.log(nodejsSetupScript);

const combinedNodejsSetupScript = `
${nodejsSetupScript}

# Additional scripts to run after nodejsSetupScript
echo "Running additional setup scripts..."

# Set environment variable for DB IP
echo "DB_PRIVATE_IP=${mysqlInstancePrivateIp}" >> /etc/environment
`;

const nodejsEc2Instance = new aws.ec2.Instance("nodejs-ec2-instance", {
	ami: "ami-01811d4912b4ccb26", // Ubuntu AMI
	instanceType: "t2.micro",
	keyName: keyPair.keyName,
	vpcSecurityGroupIds: [nodejsSecurityGroup.id],
	subnetId: publicSubnet.id,
	userData: combinedNodejsSetupScript,
});

export const vpcName = vpc.id;
