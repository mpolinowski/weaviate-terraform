resource "kubernetes_deployment_v1" "weaviate" {
  metadata {
    name      = "weaviate"
    namespace = kubernetes_namespace_v1.weaviate.metadata[0].name
    labels = {
      app                          = "weaviate"
      "app.kubernetes.io/name"     = "weaviate"
      "app.kubernetes.io/component" = "vector-database"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weaviate"
      }
    }

    strategy {
      # Single replica with hostPath + hostPort: recreate avoids port conflicts.
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "weaviate"
        }
      }

      spec {
        # Single-node dev cluster: tolerate a control-plane NoSchedule taint if
        # present so the pod lands on the only node.
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name              = "weaviate"
          # Image was imported locally from weaviate.tar (registry unreachable from this network).
          image             = "cr.weaviate.io/semitechnologies/weaviate:1.39.7"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            host_port      = 8080
          }
          port {
            name           = "grpc"
            container_port = 50051
            host_port      = 50051
          }

          env {
            name  = "QUERY_DEFAULTS_LIMIT"
            value = "25"
          }

          env {
            name  = "AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED"
            value = "true"
          }

          env {
            name  = "PERSISTENCE_DATA_PATH"
            value = "/var/lib/weaviate"
          }

          readiness_probe {
            http_get {
              path = "/v1"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }

          liveness_probe {
            http_get {
              path = "/v1"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            timeout_seconds       = 5
          }

          volume_mount {
            name       = "weaviate-data"
            mount_path = "/var/lib/weaviate"
          }

          resources {
            limits = {
              cpu    = "2000m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "weaviate-data"
          host_path {
            # Persist all DB data inside the workspace.
            path = "/home/kentaro/Projects/terraform/weaviate/data"
            type = "DirectoryOrCreate"
          }
        }

        dns_policy                     = "ClusterFirst"
        restart_policy                 = "Always"
        termination_grace_period_seconds = 30
      }
    }
  }
}
