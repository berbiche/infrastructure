# Terraform

This repository contains all Terraform configuration.

![Graph of the dependencies](./graph.svg)

## Secrets

Secrets are automatically encrypted/decrypted using `git-crypt`.
To see/modify the list of encrypted files, please modify the `.gitattributes`
in the root directory.

## Development

1. Configure your local Terraform environment

```sh
terraform init
```

2. Refresh the state

```sh
terraform refresh -var-file=secrets.tfvars
```

3. Hack on and see modifications (saving the plan to "out-build")

```sh
terraform plan -var-file=secrets.tfvars -out out-build
```

4. Apply the changes

    1. Using the generated file from `terraform plan`
    
    ```sh
    terraform apply -var-file=secrets.tfvars -auto-approve out-build
    ```
    
    2. Without the generated file
    
    ```sh
    terraform apply -var-file=secrets.tfvars
    ```

## Importing existing resources

Importing an existing resource (example with Cloudflare):

```sh
terraform import -var-file=secrets.tfvars cloudflare_zone.my_resource_in_my_dot_tf cloudflare-zone-id
```

## Creating a graph of the dependencies

```sh
terraform graph | dot -Tsvg >graph.svg
```
