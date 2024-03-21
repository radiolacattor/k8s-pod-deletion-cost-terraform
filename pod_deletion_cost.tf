resource "kubernetes_namespace" "pod_deletion_cost_test" {
  metadata {
    name = "pod-deletion-cost-test"
  }
}

resource "kubernetes_deployment" "pod_deletion_cost_test" {
  metadata {
    namespace = kubernetes_namespace.pod_deletion_cost_test.metadata[0].name
    name      = "pod-deletion-cost-test"
    labels = {
      app = "pod-deletion-cost-test"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pod-deletion-cost-test"
      }
    }

    template {
      metadata {
        labels = {
          app = "pod-deletion-cost-test"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx-container"
          resources {
            limits = {
              cpu    = "1"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pod_deletion_cost_test" {
  metadata {
    namespace = kubernetes_namespace.pod_deletion_cost_test.metadata[0].name
    name      = "pod-deletion-cost-test"
  }

  spec {
    selector = kubernetes_deployment.pod_deletion_cost_test.spec[0].template[0].metadata[0].labels
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "pod_deletion_cost_test" {
  metadata {
    namespace = kubernetes_namespace.pod_deletion_cost_test.metadata[0].name
    name      = "pod-deletion-cost-test-hpa"
  }

  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = kubernetes_deployment.pod_deletion_cost_test.metadata[0].name
      api_version = "apps/v1"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = "60"
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "pod_deletion_cost_test" {
  metadata {
    namespace = kubernetes_namespace.pod_deletion_cost_test.metadata[0].name
    name      = "pod-deletion-cost-test-job"
  }

  spec {
    schedule = "0 * * * *" # Every hour

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "pod-deletion-cost-test-job"
              image   = "httpd" # Apache Bench (ab) is included in httpd image
              command = ["ab"]
              args    = ["-k", "-n", "500000", "-c", "10", "http://pod-deletion-cost-test:80/"] # Load for 15 minutes with 100 concurrent connections
            }
          }
        }
      }
    }

    concurrency_policy = "Forbid"
    suspend            = false
  }
}
