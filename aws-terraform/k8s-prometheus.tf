resource "kubernetes_namespace" "prometheus" {
  count = var.deploy_prometheus ? 1 : 0
  metadata {
    annotations = {
      name = "prometheus"
    }

    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  count      = var.deploy_prometheus ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.prometheus[0].metadata[0].name
  version    = "82.10.5"
}
