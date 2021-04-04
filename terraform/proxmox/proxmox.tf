locals {
  # Amount of VMs to create: X nodes + 1 master
  vm_count = var.node_count + 1
}

resource "null_resource" "create_template_vm" {
  connection {
    type = "ssh"
    user = var.ssh_user
    host = var.ssh_host
    private_key = file(var.ssh_private_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "wget -q -O /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img",
      # "qm create 1000 --memory 16384 --net0 virtio,bridge=vmbr0,tag=42 --cpu=host --socket=1 --cores=6 --ostype=other --serial0=socket --vga=serial0 --agent=1
      "qm create 1000 --memory 1024 --net0 virtio,bridge=vmbr0 --cpu=host --name='cloudimage-ubuntu-template'",
      "qm importdisk 1000 /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img ${var.thinpool}",
      "qm set 1000 --ide2=${var.thinpool}:cloudinit --boot=c --bootdisk=scsi0",
      "qm set 1000 --scsihw=virtio-scsi-pci --scsi0=${var.thinpool}:vm-1000-disk-0",
      "qm set 1000 --serial0=socket --boot=c --bootdisk=scsi0",
      "qm template 1000"
    ]
  }
  # provisioner "remote-exec" {
  #   when = destroy
  #   inline = [
  #     "rm /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img",
  #     "qm destroy 1000"
  #   ]
  # }
}

resource "random_integer" "mac_address_prefix" {
  count = 2
  min = 0
  max = 255
  keepers = {
    proxmox_host = var.host
  }
}

resource "macaddress" "k8s_node_mac_addresses" {
  count = local.vm_count
  # 4A:XX:XX
  prefix = [74, random_integer.mac_address_prefix[0].result, random_integer.mac_address_prefix[1].result]
}

resource "null_resource" "cloud_init_config_files" {
  count = local.vm_count
  triggers = {
    config_contents = filesha256("${path.module}/templates/user_data.cfg.tmpl")
  }
  connection {
    type = "ssh"
    user = var.ssh_user
    host = var.ssh_host
    private_key = file(var.ssh_private_key_path)
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/user_data.cfg.tmpl", {
      hostname = "k8s-${var.host}-node${count.index + 1}"
      fqdn = "k8s-${var.host}-node${count.index + 1}node.tq.rs"
      authorized-key-nicolas = file("${path.root}/../files/keanu.ovh.pub")
      authorized-key-automation = file("${path.root}/../files/automation.pub")
      timezone = "America/Montreal"
      ip4 = var.ipv4_addresses[count.index]
      gateway4 = var.ipv4_gateway
      nameservers = var.nameservers
      macaddress = upper(macaddress.k8s_node_mac_addresses[count.index].address)
      hashed-password = var.secrets.hashed_password
    })
    destination = "/var/lib/vz/snippets/user_data_vm-${var.host}-${count.index}.yml"
  }
}

resource "proxmox_vm_qemu" "cloud-vms" {
  count = local.vm_count
  name = "k8s-${var.host}-node${count.index + 1}.node.tq.rs"
  desc = "Kubernetes Ubuntu 20.04 (Focal) node"
  target_node = var.host

  clone = "cloudimage-ubuntu-template"

  depends_on = [
    null_resource.create_template_vm,
    null_resource.cloud_init_config_files
  ]

  force_recreate_on_change_of = filesha256("${path.module}/templates/user_data.cfg.tmpl")

  os_type = "cloud-init"
  agent = 1
  cicustom = "user=local:snippets/user_data_vm-${var.host}-${count.index}.yml"
  ipconfig0 = "ip=${var.ipv4_addresses[count.index]},gw=${var.ipv4_gateway}"
  nameserver = element(var.nameservers, 0)
  # nameserver = jsonencode(var.nameservers)
  onboot = true

  cpu = "host"
  sockets = 1
  cores = 6
  memory = 16384
  scsihw = "virtio-scsi-pci"

  # Only boot from disk
  boot = "c"
  bootdisk = "scsi0"

  disk {
    format = "qcow2"
    type = "scsi"
    storage = var.thinpool
    size = "64000M"
    iothread = 1
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = 42
    macaddr = upper(macaddress.k8s_node_mac_addresses[count.index].address)
  }
  serial {
    id = 0
    type = "socket"
  }

  lifecycle {
    ignore_changes = [
      disk,
    ]
  }
}
