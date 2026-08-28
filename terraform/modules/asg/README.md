# Auto Scaling Group

Creates an EC2 launch template and an Auto Scaling Group. The launch template
supports the same core instance settings as the VM module: AMI, name, instance
type, one configurable root disk, cloud-init user data, security groups,
public-IP association, an optional IAM instance profile, and tags. The Auto
Scaling Group adds subnet placement and capacity controls.

~~~hcl
module "vault" {
  source = "../../modules/asg"

  ami        = data.aws_ami.vault.id
  name       = "vault"
  subnet_ids = [module.vpc.private_subnet_id]

  instance_type               = "t3.micro"
  root_disk_size              = 20
  associate_public_ip_address = false
  user_data                   = file("${path.module}/cloud-init/vault.yaml")

  min_size         = 1
  desired_capacity = 1
  max_size         = 3
}
~~~

The default capacity is one instance. Launch template changes trigger a
rolling instance refresh by default; disable this with
`instance_refresh_enabled = false` if replacement should be managed
separately. Use `target_group_arns` to register instances with an ALB or NLB.

The `root_device_name` default is `/dev/sda1`, which is the usual root device
name for EBS-backed AMIs. Override it when the selected AMI reports a different
root device mapping. Root volumes are encrypted gp3 volumes deleted with their
instances.

Set `iam_instance_profile_name` when instances need AWS API permissions (for
example, Nomad's AWS cloud auto-join).

Launch templates do not expose EC2 `source_dest_check`; workloads that need it
disabled require a separately managed network interface. `user_data` is
base64-encoded for the launch template and is stored in Terraform state, so
protect state files containing cloud-init secrets.
