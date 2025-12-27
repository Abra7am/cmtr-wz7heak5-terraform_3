resource "aws_instance" "cmtr_wz7heak5_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  subnet_id              = data.aws_subnet.public.id
  vpc_security_group_ids = [data.aws_security_group.this.id]

  tags = {
    Name      = "cmtr-wz7heak5-instance"
    Project   = var.project_id
    Terraform = "true"
  }
}
