resource "kubernetes_service_v1" "weaviate" {
  metadata {
    name      = "weaviate"
    namespace = kubernetes_namespace_v1.weaviate.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "weaviate"
    }
  }

  spec {
    selector = {
      app = "weaviate"
    }

    # In-cluster DNS name: weaviate.weaviate.svc.cluster.local
    # Localhost access is served by the hostPort bindings (8080 / 50051),
    # so localhost:8080 == container 8080 exactly as in the Docker docs.
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
    port {
      name        = "grpc"
      port        = 50051
      target_port = 50051
    }

    type = "ClusterIP"
  }
}
