# Create an Internet Gateway
resource "aws_internet_gateway" "igw_jenkins" {
  vpc_id = aws_vpc.main_vpc_jenkins.id

  tags = {
    Name = "main_igw_jenkins"
  }
}
