# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

- [NixOS](https://nixos.org) for the declarative OS and service configuration
- [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
- [Terraform](https://terraform.io) for the automated DNS and OVH configuration
- [Backblaze](https://www.backblaze.com) for the cheap object storage


TODO: https://plantuml.com/nwdiag


## Initial configuration

### Configuring the VPS

- Create a VPS at `$HOSTING_PROVIDER`
- `nixos-infect` the VPS

### Configuring Terraform

Enter the shell with `nix-shell` to get access to all the required variables
and to be able to use the `terraform-provider-b2`.

- Get an API token from OVH and update `secrets/ovh.yaml`
- Get an API token from Cloudflare and update `secrets/cloudflare.yaml`
- Get an API token from Backblaze and update `secrets/backblaze.yaml`
- Create a Backblaze bucket and application key for that bucket for the
  Terraform state and update `secrets/terraform-backend.yaml`

All required secrets keys are public in the appropriate SOPS file in `secrets/`
(but not their values).

- `cd terraform && terraform init`

## SOPS Cheatsheet

``` console
$ sops -i secrets/cloudflare.yaml
edit stuff in $EDITOR
:wq

File is encrypted inline
```

``` console
$ sops exec-env secrets/some-file bash
bash-4.4$
```

## Terraform

The Terraform state is managed outside of the repository in a B2 bucket.

Terraform needs to be run from the FHS provided in the flake default package
because the Backblaze B2 provider extracts a binary embedded in its binary
and the paths needs to be `patchelf`d.

`nix-shell` will spawn you in the FHS with the required packages for the
Terraform B2 plugin to work.

## Backblaze

Documentation about capabilities:
<https://www.backblaze.com/b2/docs/application_keys.html>

Retention settings for the dovecot email bucket: 30 days

## Kubernetes deployment

### Proxmox

I use Proxmox VMs as Kubernetes nodes since I don't have enough baremetal servers.

My VMs are CPU and memory overcommitted.

1. Create a user to access and control Proxmox for Terraform

    ``` console
    root@proxmox:~# pveum user add terraform@pve --password temporary-password
    root@proxmox:~# pveum aclmod / -user terraform@pve -role Administrator
    ```

2. Change the user's password to a strong password generated only for Terraform.

   I had to set the password in the web interface as I couldn't find a way to
   input the password without it being in the shell's history.

A base VM template has to be created initially for the nodes used in Terraform.

This is currently done with Terraform's `remote-exec` provisioner but can also be done
manually:

**OPTIONAL**

1. ssh into an host
2. Download Ubuntu 20.04 Focal with
`wget -P /var/lib/vz/template/iso/ https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img`
3. Create the VM:
  `qm create 1000 --memory 16384 --net0 virtio,bridge=vmbr0,tag=42 --cpu=host --socket=1 --cores=6 --ostype=other --serial0=socket --agent=1 --name="cloudimage-ubuntu-template"`
4. `qm importdisk 1000 /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img proxthin`
5. `qm set 1000 --ide2=proxthin:cloudinit --boot=c --bootdisk=scsi0`
6. `qm set 1000 --scsihw=virtio-scsi-pci --scsi0=proxthin:vm-1000-disk-0`
7. `qm template 1000`

Where `proxthin` is the name of the LVM thin provisioner on the Proxmox host.

## Kubespray

See the documentation in `kubespary/README.md`

## NixOS

## Deployment

Using deploy-rs, `deploy .#mouse --auto-rollback=false` for instance.

### Modules

I host different services on my NixOS VMs.
