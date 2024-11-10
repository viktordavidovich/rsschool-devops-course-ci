# Create a public route table and associate with public subnets
resource "aws_route_table" "public_rt_jenkins" {
  vpc_id = aws_vpc.main_vpc_jenkins.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_jenkins.id
  }

  tags = {
    Name = "public_route_table_jenkins"
  }
}
# Associate public route table with public subnets
resource "aws_route_table_association" "public_association_jenkins" {
  subnet_id      = aws_subnet.public_subnet_jenkins.id
  route_table_id = aws_route_table.public_rt_jenkins.id
}
