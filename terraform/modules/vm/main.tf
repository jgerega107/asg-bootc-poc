resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = var.associate_public_ip_address
  source_dest_check           = var.source_dest_check

  iam_instance_profile = aws_iam_instance_profile.this.name

  user_data                   = var.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_disk_size
    volume_type           = "gp3"
    encrypted             = var.root_disk_encrypted
    delete_on_termination = true
  }

  volume_tags = merge(var.tags, {
    Name = "${var.name}-root"
  })

  tags = merge(var.tags, {
    Name = var.name
  })
}
