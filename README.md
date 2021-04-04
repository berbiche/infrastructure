
# Table of Contents

1.  [My OVH VPS configuration](#my-ovh-vps-configuration)
    1.  [Initial configuration](#initial-configuration)
        1.  [Configuring the VPS](#configuring-the-vps)
        2.  [Configuring Terraform](#configuring-terraform)
    2.  [SOPS Cheatsheet](#sops-cheatsheet)
    3.  [Terraform](#terraform)
    4.  [Backblaze](#backblaze)
    5.  [Kubernetes deployment](#kubernetes-deployment)
        1.  [Proxmox](#proxmox)
    6.  [Kubespray](#kubespray)
        1.  [Kubespray deployment](#kubespray-deployment)
    7.  [NixOS](#nixos)
        1.  [Deployment](#deployment)
        2.  [Modules](#modules)


<a id="my-ovh-vps-configuration"></a>

# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

-   [NixOS](https://nixos.org) for the declarative OS and service configuration
-   [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
-   [Terraform](https://terraform.io) for the automated DNS and OVH configuration
-   [Backblaze](https://www.backblaze.com) for the cheap object storage

TODO: <https://plantuml.com/nwdiag>


<a id="initial-configuration"></a>

## Initial configuration


<a id="configuring-the-vps"></a>

### Configuring the VPS

-   Create a VPS at `$HOSTING_PROVIDER`
-   `nixos-infect` the VPS


<a id="configuring-terraform"></a>

### Configuring Terraform

Enter the shell with `nix-shell` to get access to all the required
variables and to be able to use the `terraform-provider-b2`.

-   Get an API token from OVH and update `secrets/ovh.yaml`
-   Get an API token from Cloudflare and update `secrets/cloudflare.yaml`
-   Get an API token from Backblaze and update `secrets/backblaze.yaml`
-   Create a Backblaze bucket and application key for that bucket for the
    Terraform state and update `secrets/terraform-backend.yaml`

All required secrets keys are public in the appropriate SOPS file in
`secrets/` (but not their values).

-   `cd terraform && terraform init`


<a id="sops-cheatsheet"></a>

## SOPS Cheatsheet

    $ sops -i secrets/cloudflare.yaml
    edit stuff in $EDITOR
    :wq
    
    File is encrypted inline

    $ sops exec-env secrets/some-file bash
    bash-4.4$


<a id="terraform"></a>

## Terraform

The Terraform state is managed outside of the repository in a B2 bucket.

Terraform needs to be run from the FHS provided in the flake default
package because the Backblaze B2 provider extracts a binary embedded in
its binary and the paths needs to be =patchelf=d.

`nix-shell` will spawn you in the FHS with the required packages for the
Terraform B2 plugin to work.


<a id="backblaze"></a>

## Backblaze

Documentation about capabilities:
<https://www.backblaze.com/b2/docs/application_keys.html>

Retention settings for the dovecot email bucket: 30 days


<a id="kubernetes-deployment"></a>

## Kubernetes deployment


<a id="proxmox"></a>

### Proxmox

I use Proxmox VMs as Kubernetes nodes since I don&rsquo;t have enough
baremetal servers.

My VMs are CPU and memory overcommitted.

1.  Create a user to access and control Proxmox for Terraform
    
        root@proxmox:~# pveum user add terraform@pve --password temporary-password
        root@proxmox:~# pveum aclmod / -user terraform@pve -role Administrator

2.  Change the user&rsquo;s password to a strong password generated only for
    Terraform.
    
    I had to set the password in the web interface as I couldn&rsquo;t find a
    way to input the password without it being in the shell&rsquo;s history.

A base VM template has to be created initially for the nodes used in
Terraform.

This is currently done with Terraform&rsquo;s `remote-exec` provisioner but
can also be done manually:

**OPTIONAL**

1.  ssh into an host
2.  Download Ubuntu 20.04 Focal with
    `wget -P /var/lib/vz/template/iso/ https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img`
3.  Create the VM:
    `qm create 1000 --memory 16384 --net0 virtio,bridge=vmbr0,tag=42 --cpu=host --socket=1 --cores=6 --ostype=other --serial0=socket --agent=1 --name`&ldquo;cloudimage-ubuntu-template&rdquo;=
4.  `qm importdisk 1000 /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img proxthin`
5.  `qm set 1000 --ide2=proxthin:cloudinit --boot=c --bootdisk=scsi0`
6.  `qm set 1000 --scsihw=virtio-scsi-pci --scsi0=proxthin:vm-1000-disk-0`
7.  `qm template 1000`

Where `proxthin` is the name of the LVM thin provisioner on the Proxmox
host.


<a id="kubespray"></a>

## Kubespray


<a id="kubespray-deployment"></a>

### Kubespray deployment

After deploying the Proxmox VMs, update the `inventory/hosts.yml` file.

To deploy (within the nix environment):

    nicolas:keanu.ovh$ cd kubespray/kubespray
    nicolas:kubespray$ pipenv shell
    nicolas:kubespray$ ansible-playbook -i ../inventory/hosts.yml cluster.yml -u automation -b -v --private-key=~/.ssh/automation


<a id="nixos"></a>

## NixOS


<a id="deployment"></a>

### Deployment

Using deploy-rs, `deploy .#mouse --auto-rollback=false` for instance.


<a id="modules"></a>

### Modules

I host different services on my NixOS VMs.

