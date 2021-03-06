
data "amazon-ami" "autogenerated_1" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20220420"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "eu-west-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ebs-build" {
  ami_name         = "packer-jenkins ${local.timestamp}"
  ami_users        = ["517672327923"]
  communicator     = "ssh"
  encrypt_boot     = true
  force_deregister = true
  instance_type    = "t2.micro"
  kms_key_id       = "arn:aws:kms:eu-west-1:517672327923:key/6fb7e1a4-44cd-4950-aba5-88714426201b"
  tags = {
    Name = "Ubuntu-Image-Packer"
  }
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    encrypted             = true
    kms_key_id            = "arn:aws:kms:eu-west-1:517672327923:key/6fb7e1a4-44cd-4950-aba5-88714426201b"
    volume_type           = "gp3"
  }
  region                    = "eu-west-1"
  source_ami                = "${data.amazon-ami.autogenerated_1.id}"
  ssh_clear_authorized_keys = true
  ssh_username              = "ubuntu"
  ssh_port                  = 22
  #ssh_interface             = "session_manager"
  #iam_instance_profile      = "SSMInstanceProfile."
  ssh_private_key_file      = "/var/lib/jenkins/sshkey/.ssh/id_rsa"
  ssh_keypair_name          = "id_rsa"
}



build {
  sources = ["source.amazon-ebs.ebs-build"]
  hcp_packer_registry {
  bucket_name = "golden-packer-image"
  bucket_labels = {
    "hashicorp-learn" = "packer-golden-image"
    "ubuntu-version"  = "20.04"
  }
}

  provisioner "ansible" {
    extra_arguments = ["--verbose"]
    playbook_file   = "main.yml"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
