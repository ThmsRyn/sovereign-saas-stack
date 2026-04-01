# Terraform — Infrastructure as Code

Terraform lets you create, configure, and destroy your VPS with code instead of clicking in a web interface. You describe the infrastructure you want in a `.tf` file, and Terraform makes it happen.

---

## When to use it

- You want to be able to recreate your entire infrastructure in minutes
- You manage staging and production environments and want them identical
- You switch providers or want to compare costs between providers

## When to skip it

- You have one server and you set it up once. Terraform adds complexity for minimal gain in that case.
- You are still learning the base stack

---

> **Sovereign note:** HashiCorp changed Terraform's license to BUSL in 2023 — the same reason this stack uses OpenBao instead of Vault. [OpenTofu](https://opentofu.org/) is the open source fork maintained by the Linux Foundation and is a drop-in replacement. Consider using OpenTofu instead of Terraform for a fully sovereign stack.

## How Terraform works

Terraform reads your `.tf` files, compares the desired state with the current state (stored in a `terraform.tfstate` file), and applies the difference.

```
terraform apply
     │
     ├── reads main.tf
     ├── compares with tfstate
     └── calls provider API
              │
              └── creates/updates/destroys resources
```

---

## Providers

A provider is a plugin that knows how to talk to a specific platform's API. This stack includes examples for:

- **Hetzner Cloud** — best price/performance ratio in Europe, good API
- **OVHcloud** — French provider, sovereign option

---

## Hetzner example

Install the Terraform CLI:

```bash
# Check the latest version at https://github.com/hashicorp/terraform/releases
# Or use OpenTofu (open source fork, drop-in replacement):
# https://opentofu.org/docs/intro/install/
TERRAFORM_VERSION="1.11.4"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

Create `main.tf`:

```hcl
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_public_key" {}

resource "hcloud_ssh_key" "default" {
  name       = "my-key"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "vps" {
  name        = "sovereign-saas"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    environment = "production"
  }
}

output "server_ip" {
  value = hcloud_server.vps.ipv4_address
}
```

Create `terraform.tfvars` (never commit this file):

```hcl
hcloud_token   = "your-hetzner-api-token"
ssh_public_key = "ssh-ed25519 AAAA..."
```

Deploy:

```bash
terraform init
terraform plan
terraform apply
```

Destroy:

```bash
terraform destroy
```

---

## State file

Terraform stores the current state of your infrastructure in `terraform.tfstate`. This file contains sensitive information (IPs, resource IDs). Never commit it to git.

For team use or CI/CD, store the state remotely (Terraform Cloud, S3-compatible storage, etc.).

Add to `.gitignore`:

```
*.tfstate
*.tfstate.backup
.terraform/
terraform.tfvars
```

---

## Combining Terraform and Ansible

A common pattern: Terraform creates the server, Ansible configures it.

```bash
# 1. Create the server
terraform apply

# 2. Get the IP
SERVER_IP=$(terraform output -raw server_ip)

# 3. Configure it
ansible-playbook -i "$SERVER_IP," playbook.yml
```

---

## Further reading

- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [Hetzner Terraform provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
