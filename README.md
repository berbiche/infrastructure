

# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

-   [NixOS](https://nixos.org) for the declarative OS and service configuration
-   [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
-   [Terraform](https://terraform.io) for the automated DNS and OVH configuration
-   [Backblaze](https://www.backblaze.com) for the cheap object storage

TODO: <https://plantuml.com/nwdiag>

1.  [Initial configuration](#org4b4fd7a)
    1.  [Configuring the VPS](#org31b147a)
    2.  [Configuring Terraform](#org7322ff7)
2.  [SOPS Cheatsheet](#orgd3a90e7)
3.  [Terraform](#orgbfda07a)
4.  [Backblaze](#orgedc070f)
5.  [Kubernetes](#org9f28f7c)
    1.  [Creating nodes inside of Proxmox](#orgd9c1ae7)
    2.  [Kubespray cluster deployment](#org1bc3f5c)
    3.  [Applications](#org2201832)
6.  [NixOS](#orgf10797b)
    1.  [Deployment](#org7403a1b)
    2.  [Modules](#org1280bbc)


<a id="org4b4fd7a"></a>

## Initial configuration


<a id="org31b147a"></a>

### Configuring the VPS

-   Create a VPS at `$HOSTING_PROVIDER`
-   `nixos-infect` the VPS


<a id="org7322ff7"></a>

### Configuring Terraform

Enter the shell with `nix-shell` to get access to all the required
variables and to be able to use the `terraform-provider-b2`.

-   Get an API token from OVH and update [secrets/ovh.yaml](./secrets/ovh.yaml)
-   Get an API token from Cloudflare and update [secrets/cloudflare.yaml](./secrets/cloudflare.yaml)
-   Get an API token from Backblaze and update [secrets/backblaze.yaml](./secrets/backblaze.yaml)
-   Create a Backblaze bucket and application key for that bucket for the
    Terraform state and update [secrets/terraform-backend.yaml](./secrets/terraform-backend.yaml)

All required secrets keys are public in the appropriate SOPS file in
`secrets/` (but not their values).

-   `cd terraform && terraform init`


<a id="orgd3a90e7"></a>

## SOPS Cheatsheet

    $ sops -i secrets/cloudflare.yaml
    edit stuff in $EDITOR
    :wq
    
    File is encrypted inline

    $ sops exec-env secrets/some-file bash
    bash-4.4$


<a id="orgbfda07a"></a>

## Terraform

The Terraform state is managed outside of the repository in a B2 bucket.

Terraform needs to be run from the FHS provided in the flake default
package because the Backblaze B2 provider extracts a binary embedded in
its binary and the paths needs to be =patchelf=d.

`nix-shell` will spawn you in the FHS with the required packages for the
Terraform B2 plugin to work.


<a id="orgedc070f"></a>

## Backblaze

Documentation about capabilities:
<https://www.backblaze.com/b2/docs/application_keys.html>

Retention settings for the dovecot email bucket: 30 days


<a id="org9f28f7c"></a>

## Kubernetes


<a id="orgd9c1ae7"></a>

### Creating nodes inside of Proxmox

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
    `qm create 1000 --memory 16384 --net0 virtio,bridge=vmbr0,tag=42 --cpu=host --socket=1 --cores=6 --ostype=other --serial0=socket --agent=1 --name="cloudimage-ubuntu-template"`
4.  `qm importdisk 1000 /var/lib/vz/template/iso/focal-server-cloudimg-amd64.img proxthin`
5.  `qm set 1000 --ide2=proxthin:cloudinit --boot=c --bootdisk=scsi0`
6.  `qm set 1000 --scsihw=virtio-scsi-pci --scsi0=proxthin:vm-1000-disk-0`
7.  `qm template 1000`

Where `proxthin` is the name of the LVM thin provisioner on the Proxmox
host.


<a id="org1bc3f5c"></a>

### Kubespray cluster deployment


1.  Kubespray deployment

    After deploying the Proxmox VMs, update the `inventory/hosts.yml` file.
    
    Update the `ansible.cfg` and set the private key and user used to authenticate on nodes.
    
    To deploy (within the nix environment):
    
    1.  Upgrading calico version
        1.  Get the latest sha256 of calicoctl of calicocrd
            
                $ wget -q -O- https://github.com/projectcalico/calicoctl/releases/download/${VERSION}/calicoctl-linux-amd64 | sha256sum -
                $ wget -q -O- https://github.com/projectcalico/calico/archive/${VERSION}.tar.gz | sha256sum -
        2.  Update the hashes in `./inventory/group_vars/k8s-cluster/k8s-net-calico.yml`
    2.  Download Calico CRD (because it fails for some reason with kubespray)
    
        kubectl apply -f https://docs.projectcalico.org/manifest/calico.yaml
    
    1.  Run the kubespray ansible playbook
    
        nicolas:keanu.ovh$ cd kubespray/kubespray
        nicolas:kubespray$ pipenv shell
        nicolas:kubespray$ ansible-playbook -i ../inventory/hosts.yaml cluster.yml --become
    
    1.  Reboot physical nodes (optional but was required in my case)

2.  Playbook

    A playbook to run after the kubespray deployment is available in `playbook.yaml`.
    
        ansible-playbook playbook.yaml


<a id="org2201832"></a>

### Applications

This requires the [kustomize-sops plugin](https://github.com/viaduct-ai/kustomize-sops).
This plugin is automatically exposed in the flake shell.

To encrypt a secret: `sops -i -e k8s/something/overlays/prod/secrets/some-secret` for instance.


<a id="orgf10797b"></a>

## NixOS


<a id="org7403a1b"></a>

### Deployment

Using deploy-rs, `deploy .#mouse --auto-rollback=false` for instance.


<a id="org1280bbc"></a>

### Modules

I host different services on my NixOS VMs.

