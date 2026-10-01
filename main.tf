terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  # Authenticate against the local single-node cluster using the kubeconfig.
  config_path    = "~/.kube/config"
  config_context = "kubernetes-admin@kubernetes"
}

resource "kubernetes_namespace_v1" "weaviate" {
  metadata {
    name = "weaviate"
  }
}
