terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.56.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.4.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}


provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    # Allow ephemeral OAuth2 relay Key Vaults to be fully purged on destroy so
    # repeated test/CI runs (and idempotence checks) do not collide with
    # soft-deleted vaults of the same name.
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}


provider "zpa" {
}
