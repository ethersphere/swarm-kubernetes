resource "aws_vpc" "swarm" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "swarm" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.swarm.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "swarm" {
  vpc_id = "${aws_vpc.swarm.id}"

  tags {
    Name = "${var.cluster-name}"
  }
}

resource "aws_route_table" "swarm" {
  vpc_id = "${aws_vpc.swarm.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.swarm.id}"
  }
}

resource "aws_route_table_association" "swarm" {
  count = 2

  subnet_id      = "${aws_subnet.swarm.*.id[count.index]}"
  route_table_id = "${aws_route_table.swarm.id}"
}
