

# My new infrastructure repository

In this repository resides the configuration for my new homelab
and some of my VPS hosts.

Technologies used:

-   [NixOS](https://nixos.org) for the declarative OS and service configuration
-   [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
-   [Terraform](https://terraform.io) for the automated DNS and OVH configuration
-   [Backblaze](https://www.backblaze.com) for the cheap object storage
-   [Ansible](https://github.com/ansible/ansible) for imperative configuration management with tasks, roles, etc.

TODO: <https://plantuml.com/nwdiag>


## Table of contents

1.  [Table of contents](#table-of-contents)
2.  [Initial configuration](#initial-configuration)
    1.  [Configuring the VPS](#configuring-the-vps)
    2.  [Configuring Terraform](#configuring-terraform)
3.  [SOPS Cheatsheet](#sops-cheatsheet)
4.  [Terraform](#terraform)
5.  [Backblaze](#backblaze)
6.  [Kubernetes](#kubernetes)
    1.  [Creating nodes inside of Proxmox](#creating-nodes-inside-of-proxmox)
    2.  [Pinning CPUs to specific nodes](#pinning-cpus-to-specific-nodes)
    3.  [Kubespray cluster deployment](#kubespray-cluster-deployment)
    4.  [Applications](#applications)
7.  [NixOS](#nixos)
    1.  [Deployment](#deployment)
    2.  [Modules](#modules)


## Initial configuration


### Configuring the VPS

-   Create a VPS at `$HOSTING_PROVIDER`
-   `nixos-infect` the VPS


### Configuring Terraform

Enter the shell with `nix run .#terraform-fhs` to get access to all the required
variables and to be able to use the `terraform-provider-b2`.

-   Get an API token from OVH and update [secrets/ovh.yaml](./secrets/ovh.yaml)
-   Get an API token from Cloudflare and update [secrets/cloudflare.yaml](./secrets/cloudflare.yaml)
-   Get an API token from Backblaze and update [secrets/backblaze.yaml](./secrets/backblaze.yaml)
-   Create a Backblaze bucket and application key for that bucket for the
    Terraform state and update [secrets/terraform-backend.yaml](./secrets/terraform-backend.yaml)

All required secrets keys are public in the appropriate SOPS file in
`secrets/` (but not their values).

-   `cd terraform && terraform init`


## SOPS Cheatsheet

    $ sops -i secrets/cloudflare.yaml
    edit stuff in $EDITOR
    :wq
    
    File is encrypted inline

    $ sops exec-env secrets/some-file bash
    bash-4.4$


## Terraform

The Terraform state is managed outside of the repository in a B2 bucket.

Terraform needs to be run from the FHS provided in the flake default
package because the Backblaze B2 provider extracts a binary embedded in
its binary and the paths needs to be =patchelf=d.

`nix-shell` will spawn you in the FHS with the required packages for the
Terraform B2 plugin to work.


## Backblaze

Documentation about capabilities:
<https://www.backblaze.com/b2/docs/application_keys.html>

Retention settings for the dovecot email bucket: 30 days


## Kubernetes


### Creating nodes inside of Proxmox

I use Proxmox VMs as Kubernetes nodes since I don't have enough
baremetal servers.

My VMs are not overcommitted.

1.  Create a user to access and control Proxmox for Terraform
    
        root@proxmox:~# pveum user add terraform@pve --password temporary-password
        root@proxmox:~# pveum aclmod / -user terraform@pve -role Administrator

2.  Change the user's password to a strong password generated only for
    Terraform.
    
    I had to set the password in the web interface as I couldn't find a
    way to input the password without it being in the shell's history.

A base VM template has to be created initially for the nodes used in
Terraform.

This is currently done with Terraform's `remote-exec` provisioner but
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


### Pinning CPUs to specific nodes

To improve performance of the nodes, verify whether the CPU supports pinning nodes
with `numactl --hardware`.
Qemu supports pinning VMs to specific cores thanks to NUMA.
If numa is supported, set each nodes' numa configuration:
`qm set <vm-id> --numa<numa number node> cpus=0,1,2,3-5, ....`


### Kubespray cluster deployment


1.  Kubespray deployment

    After deploying the Proxmox VMs, update the `inventory/hosts.yml` file.
    
    Update the `ansible.cfg` and set the private key and user used to authenticate on nodes.
    
    To reset the host in `~/.ssh/known_hosts`, run the following
    `for i in {0..nb_host}; do ssh-keygen -R $ip_address$i; done`
    (Assuming continuous IP space for the different hosts)
    
    To deploy (within the nix environment):
    
    1.  Upgrading calico version
        a. Get the latest sha256 of calicoctl of calicocrd
        
            $ wget -q -O- https://github.com/projectcalico/calicoctl/releases/download/${VERSION}/calicoctl-linux-amd64 | sha256sum -
            $ wget -q -O- https://github.com/projectcalico/calico/archive/${VERSION}.tar.gz | sha256sum -
        
        b. Update the hashes in `./inventory/group_vars/k8s-cluster/k8s-net-calico.yml`
    2.  Download Calico CRD (because it fails for some reason with kubespray)
        
            kubectl apply -f https://docs.projectcalico.org/manifest/calico.yaml
    3.  Run the kubespray ansible playbook
        
            nicolas:keanu.ovh$ cd kubespray
            nicolas:kubespray$ ansible-playbook cluster.yml --become
    4.  Reboot physical nodes (optional but was required in my case)

2.  Playbook

    A playbook to run after the kubespray deployment is available in `playbook.yaml`.
    
        ansible-playbook playbook.yaml


### Applications

This requires the [kustomize-sops plugin](https://github.com/viaduct-ai/kustomize-sops).
This plugin is automatically exposed in the flake shell.

To encrypt a secret: `sops -i -e k8s/something/overlays/prod/secrets/some-secret` for instance.

1.  Technologies

    -   Kustomize to scaffold, modify and apply patches on top of external resources
    -   Cert-manager to manage certificates
    -   metallb to manage ip allocation in the cluster
    -   calico as the CNI
    -   longhorn for disk and storage provisioning
    -   ExternalDNS to expose DNS records to Cloudflare

2.  Kustomize

        kustomize build --enable-alpha-plugins something/overlays/prod
        kustomize build --enable-alpha-plugins something/overlays/prod | kubectl apply -f -

3.  Deployment

    1.  Deploy metallb
    2.  Deploy external-dns (has no dependencies)
    3.  Deploy cert-manager
    4.  Reapply cert-manager
    5.  Deploy OpenEBS `overlays/prod`
    6.  Fix OpenEBS disks pool
    7.  Reapply OpenEBS `overlays/prod`
    8.  Deploy Traefik `overlays/prod`
    9.  Reapply Traefik for to apply ingresses
    10. Deploy Monitoring stack `overlays/prod`
    11. Reapply Traefik for the monitoring stuff `overlays/prod`
    12. Reapply OpenEBS for the monitoring stuff `overlays/monitoring`
    13. Deploy the remaining resources

4.  ExternalDNS

    ExternalDNS automatically inserts CNAME entries to `k8s.qt.rs` for each ingress I define
    and annotate with the `external-dns.alpha.kubernetes.io/target: k8s.qt.rs`.
    
    While I could use a generic `*` CNAME entry that points to `k8s.qt.rs`, I prefer having
    unresolvable domains (this is not a security by obscurity thing, I'd rather have an NX domain than a 404 status page).
    
    Domains that only allow access by administrators (myself) are gated behind a OAuth middleware in Traefik.

5.  OpenEBS

    I use OpenEBS for storage because I have local disks attached directly to my server (i.e. a "hyper-converged" installation).
    
    OpenEBS has multiple backends. I use the cStor backend because it has better performance than the Jiva backend.
    
    <del>I use the Mayastor backend instead of the Jiva/cStor because the performance of the backend seemed good.</del>
    The in-development Mayastor backend currently (2021-06-30) uses a busy-loop which pins 1 cpu core per-host where OpenEBS has a pod running.
    This mecanism is used to ensure events are always processed in due time.
    The downside is that it uses a full cpu core on a node, increasing the heat and power usage.
    I observed an increase in power usage of at least 60W using Mayastor on 4 k8s nodes in Proxmox.
    For this reason, I chose to use the cStor backend.
    
    1.  Configuration
    
        1.  Add raw disks to Proxmox VMs (disk passthrough)
            
            For each VM, attach one disk for high availability (in case of disk failure or virtual node failure).
            
                # Identify disks
                root@proxmox:~# ls -l /dev/disk/by-id
                ...
                root@proxmox:~# qm set $VM_ID -scsi1 /dev/disk/by-id/ata-something-something
            
            If any disks were part of a zfs pool, the zfs<sub>member</sub> label must be cleared:
            
                root@proxmox:~# lsblk -f
                root@proxmox:~# zpool labelclear -f /dev/disk/by-id/the-disk
    
    2.  Debugging
    
        Sometimes BlockDevices will remain in an unclaimed state if they still have old information.
        This can be verified with the following command:
        
            $ kubectl get bd -n openebs -o yaml | grep internal
              internal.openebs.io/partition-uuid: <uuid>
              internal.openebs.io/uuid-scheme: legacy
              # Or
              internal.openebs.io/fsuuid: <uuid>
              internal.openebs.io/uuid-scheme: legacy
        
        If any of these two things appear then the disks must be cleared, the node-disk-manager pods deleted (to be recreated) and the bd/bdc removed.
        
            root@proxmox:~# for i in {a,b,c}; do
              wipefs -fa /dev/sd$i;
              dd if=/dev/zero of=/dev/sd$i bs=4M count=1 conv=notrunc oflag=sync status=progress;
            done
            
            $ kubectl delete -n openebs bd --all
            $ kubectl delete -n openebs bdc --all
            $ kubectl delete -n openebs pods -l name=openebs-ndm
    
    3.  Other
    
        OpenEBS automatically detects disks attached to nodes with [Node Disk Manager](https://github.com/openebs/node-disk-manager).
        Nodes that serve a storage backend for NDM have a label set on them: `openebs.io/nodegroup: storage-node`.
        <del>These nodes additionnaly have a label to identify the OpenEBS engine running on them: `openebs.io/engine: mayastor`.</del>
        
        The cStor pool definition will need to be filled out manually.
        After deploying the configuration with `kustomize build openebs/overlays/prod | kubectl apply -f -`,
        obtain the discovered block devices with `kubectl get blockdevices`.
        
        The list of block devices name will have to be used in the definition of the cStor pool.


## NixOS


### Deployment

Using deploy-rs, `deploy .#mouse --auto-rollback=false` for instance.


### Modules

I host different services on my NixOS VMs.

