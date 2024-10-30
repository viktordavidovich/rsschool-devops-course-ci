# Create public subnet for jenkins
resource "aws_subnet" "public_subnet_jenkins" {
  vpc_id            = aws_vpc.main_vpc_jenkins.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]

  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_jenkins"
  }
}



