

# My new infrastructure repository

In this repository resides the configuration for my new homelab
and some of my VPS hosts.

Technologies used:

-   [NixOS](https://nixos.org) for the declarative OS and service configuration
-   [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
-   [Terraform](https://terraform.io) for the automated DNS and OVH configuration
-   [Backblaze](https://www.backblaze.com) for the cheap object storage
-   [Ansible](https://github.com/ansible/ansible) for imperative configuration management with tasks, roles, etc.
-   [OKD](https://okd.io) is an OpenShift (Kubernetes) distribution without license requirements
-   [Ovirt](https://ovirt.org) and Ovirt Node is used on my single server to host my Kubernetes deployment

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
    1.  [Deploying oVirt Node](#org237a344)
    2.  [Installing and configuring GlusterFS](#orgb126f38)
    3.  [Deploying the HostedEngine VM](#orge8e9835)
    4.  [Configuring a new user for OCP](#org85e0995)
    5.  [Deploying OKD](#orge28789b)
    6.  [Stuff to look at](#org6620b3d)
    7.  [Applications](#applications)
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



### Deploying oVirt Node

Since I have a single server with 56 cores (vCPU) and 200GB of RAM,
I deploy my kubernetes cluster using OpenShift&rsquo;s free OKD distribution
on a single oVirt Node host.

In order to deploy OKD, the oVirt node has to be setup alongside a storage
device.
Afterwards, HostedEngine can be deployed in oVirt.


### Installing and configuring GlusterFS

1.  Make sure to generate an ssh private key (with no password) for the root user.
    1.  Then, as the root user on the ovirt node, ssh on the ovirt node (`ssh root@localhost`)
        This will add the ovirt node to the ssh `known_hosts` file.
2.  Create a raid device
3.  Setup glusterfs through Cockpit&rsquo;s UI to use the raid device
    1.  Add a brick for the kubernetes cluster with at least 500GB of space.


### Deploying the HostedEngine VM

HostedEngine needs to be deployed and should use the configured glusterfs storage.

1.  Deploy a hyperconverged HostedEngine VM through Cockpit&rsquo;s UI


### Configuring a new user for OCP

1.  Add a new user for the OCP deployment
    1.  SSH in the hosted engine
    2.  Run these commands:
        
            $ ovirt-aaa-jdbc-tool user add kubernetes --attribute=firstName=kubernetes
            $ ovirt-aaa-jdbc-tool user password-reset kubernetes
            $ ovirt-aaa-jdbc-tool user unlock kubernetes
            $ ovirt-aaa-jdbc-tool group add okd
            $ ovirt-aaa-jdbc-tool group-manage useradd okd --user kubernetes
    3.  Note down the password and modify the secret in the \`install-config.yaml\`
    4.  Add the user in the ovirt-engine administration portal under `Administration > Users`
    5.  Add the group in the ovirt-engine administration portal under `Administration > Users`
    6.  Add the following permissions to the **okd** group:
        -   `ClusterAdmin`
        -   `DiskCreator`
        -   `DiskOperator`
        -   `TemplateCreator`
        -   `TemplateOwner`
        -   `UserTemplateBasedVm`


### Deploying OKD

The steps to deploy OKD are the following:

1.  Configure a DHCP server to allocate IP addresses for the nodes
2.  Configure DNS entries
3.  Install the `openshift-install` CLI
4.  Generate the install configuration and manifests
5.  Patch the generated manifests
6.  Create the cluster with the patched manifests

1.  Configuring OKD dns entries

    OKD requires the following DNS entries during the bootstrap phase and after.
    
    -   `*.apps.{cluster}.baseDomain`: points to the Haproxy LoadBalancer IP
    -   `api-internal.{cluster}.baseDomain`: points to a virtual IP for the API server
    -   `api.{cluster}.baseDomain`: ditto

2.  Installing the `openshift` deployment CLI

    In order to deploy OKD, the `openshift-install` cli will need to be fetched from the official repository and unpacked.
    
    The cli is also available as a Nix derivation in the `Flake.nix`.
    It is automatically available when using direnv.

3.  Generating the install configuration and manifests

    1.  Generate the base configuration with `openshift-install create configs --dir .`
    2.  Fetch the latest Tigera manifests from [here](https://projectcalico.docs.tigera.io/getting-started/openshift/installation) and add them to a folder named `calico`.
        
        The script below provides an automated way of creating the `kustomization.yaml` for the Calico/Tigera manifests.
        
            $ mkdir -p calico
            # Copy the block of code and run it through this
            $ wl-paste | awk 'gsub(/manifests/, "calico", $4)' > script.sh
            $ cat script.sh
            $ bash script.sh
            $ resources="$(find calico -type f -printf '%f\0' | sort -z | xargs -r0 printf '- ./%s\n')"
            $ cat <<EOF >calico/kustomization.yaml
            apiVersion: kustomize.config.k8s.io/v1beta1
            kind: Kustomization
            
            commonAnnotations:
              qt.rs/installer-dir: manifests
            
            resources:
            $resources
            EOF
    3.  Generate the openshift manifests with `openshift-install create manifests --dir .`
        This may consume the `openshift-install.yaml` file.
    4.  Generate a `kustomization.yaml` file for the manifests in `manifests` and `openshift`

4.  Creating the cluster

    1.  Generate the final resources
        
            $ mkdir -p bootstrap/install-dir
            $ kustomize build --enable-alpha-plugins bootstrap | ./slice.py -o bootstrap/install-dir
        
        Make sure the file `manifests/cluster-config.yaml` exists.
    
    2.  Begin the installation
        
        Make sure to delete the file `install-config.yaml` in the installation directory
        or to move it out of the `install-dir` folder.
        
        The hidden file `.openshift_install_state.json` ****MUST**** exist
        otherwise the installer will not use ANY generated manifests.
        
        The installation directory should look like this:
        
            install-dir
            ├── .openshift_install_state.json
            ├── manifests
            │   ├── 00-namespace-tigera-operator.yaml
            │   ├── 01-cr-apiserver.yaml
            │   ├── 01-crd-apiserver.yaml
            │   ├── 01-crd-imageset.yaml
            │   ├── 01-crd-installation.yaml
            │   ├── 01-crd-tigerastatus.yaml
            │   ├── 01-cr-installation.yaml
            │   ├── 02-configmap-calico-resources.yaml
            │   ├── 02-rolebinding-tigera-operator.yaml
            │   ├── 02-role-tigera-operator.yaml
            │   ├── 02-serviceaccount-tigera-operator.yaml
            │   ├── 02-tigera-operator.yaml
            │   ├── 04-openshift-machine-config-operator.yaml
            │   ├── cluster-config.yaml
            │   ├── cluster-dns-02-config.yml
            │   ├── cluster-infrastructure-02-config.yml
            │   ├── cluster-ingress-02-config.yml
            │   ├── cluster-network-01-crd.yml
            │   ├── cluster-network-02-config.yml
            │   ├── cluster-proxy-01-config.yaml
            │   ├── cluster-scheduler-02-config.yml
            │   ├── configmap-root-ca.yaml
            │   ├── crd.projectcalico.org_bgpconfigurations.yaml
            │   ├── crd.projectcalico.org_bgppeers.yaml
            │   ├── crd.projectcalico.org_blockaffinities.yaml
            │   ├── crd.projectcalico.org_caliconodestatuses.yaml
            │   ├── crd.projectcalico.org_clusterinformations.yaml
            │   ├── crd.projectcalico.org_felixconfigurations.yaml
            │   ├── crd.projectcalico.org_globalnetworkpolicies.yaml
            │   ├── crd.projectcalico.org_globalnetworksets.yaml
            │   ├── crd.projectcalico.org_hostendpoints.yaml
            │   ├── crd.projectcalico.org_ipamblocks.yaml
            │   ├── crd.projectcalico.org_ipamconfigs.yaml
            │   ├── crd.projectcalico.org_ipamhandles.yaml
            │   ├── crd.projectcalico.org_ippools.yaml
            │   ├── crd.projectcalico.org_ipreservations.yaml
            │   ├── crd.projectcalico.org_kubecontrollersconfigurations.yaml
            │   ├── crd.projectcalico.org_networkpolicies.yaml
            │   ├── crd.projectcalico.org_networksets.yaml
            │   ├── cvo-overrides.yaml
            │   ├── kube-cloud-config.yaml
            │   ├── openshift-kubevirt-infra-namespace.yaml
            │   ├── secret-machine-config-server-tls.yaml
            │   └── secret-pull-secret.yaml
            └── openshift
                ├── 99_openshift-cluster-api_master-machines-0.yaml
                ├── 99_openshift-cluster-api_master-machines-1.yaml
                ├── 99_openshift-cluster-api_master-machines-2.yaml
                ├── 99_openshift-cluster-api_worker-machineset-0.yaml
                ├── 99_openshift-machineconfig_99-master-ssh.yaml
                ├── 99_openshift-machineconfig_99-worker-ssh.yaml
                ├── 99_role-cloud-creds-secret-reader.yaml
                ├── openshift-install-manifests.yaml
                ├── secret-kubeadmin.yaml
                ├── secret-master-user-data.yaml
                ├── secret-ovirt-credentials.yaml
                └── secret-worker-user-data.yaml
        
            $ openshift-install create cluster --dir install-dir --log-level=debug
            DEBUG .....
            INFO Consuming Install Config from target directory


### Stuff to look at

-   [Customizing HAProxy error code response pages](https://docs.openshift.com/container-platform/4.9/networking/ingress-operator.html#nw-customize-ingress-error-pages_configuring-ingress)
-   [Enabling HTTP Strict Transport Security per-route](https://docs.openshift.com/container-platform/4.9/networking/routes/route-configuration.html#nw-enabling-hsts-per-route_route-configuration)
-   [Creating a route through an Ingress object](https://docs.openshift.com/container-platform/4.9/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration)
-   [Installing a specific version of an Operator](https://docs.openshift.com/container-platform/4.9/operators/admin/olm-adding-operators-to-cluster.html#olm-installing-specific-version-cli_olm-adding-operators-to-a-cluster)


### Applications

This requires the [kustomize-sops plugin](https://github.com/viaduct-ai/kustomize-sops).
This plugin is automatically exposed in the flake shell.

To encrypt a secret: `sops -i -e k8s/something/overlays/prod/secrets/some-secret` for instance.

1.  Technologies

    -   Kustomize to scaffold, modify and apply patches on top of external resources
    -   Cert-manager to manage certificates
    -   metallb to manage ip allocation in the cluster
    -   calico as the CNI
    -   ExternalDNS to expose DNS records to Cloudflare
    -   OKD provides the monitoring stack and a CSI driver with the oVirt deployment

2.  Kustomize

        kustomize build --enable-alpha-plugins something/overlays/prod
        kustomize build --enable-alpha-plugins something/overlays/prod | kubectl apply -f -

3.  Deployment

    1.  Deploy metallb
    2.  Deploy external-dns
    3.  Deploy cert-manager
    4.  Deploy Traefik (has a dependency on Cert Manager and MetalLB)
    5.  Deploy the remaining resources

4.  ExternalDNS

    ExternalDNS automatically inserts CNAME entries pointing to `k8s.qt.rs` for each ingress defined
    and annotated with `external-dns.alpha.kubernetes.io/target: k8s.qt.rs`.
    
    While I could use a generic `*` CNAME entry that points to `k8s.qt.rs`, I prefer having
    unresolvable domains.
    Also, when my ISP will properly support IPv6, I will add `AAAA` records and `CNAME` records for the IPv4 scenario.
    
    Domains that only allow access by administrators (myself) are gated behind an OAuth middleware in Traefik.


## NixOS


### Deployment

Using deploy-rs, `deploy .#mouse --auto-rollback=false` for instance.


### Modules

I host different services on my NixOS VMs.

