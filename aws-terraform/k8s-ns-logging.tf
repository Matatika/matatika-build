resource "kubernetes_namespace" "operations" {
  metadata {
    annotations = {
      name = "operations"
    }

    name = "operations"
  }
}

resource "kubernetes_namespace" "env" {
  metadata {
    annotations = {
      name = "${var.environment}"
    }

    name = var.environment
  }
}


resource "kubernetes_namespace" "env-tasks" {
  metadata {
    annotations = {
      name = "${var.environment}-tasks"
    }

    name = "${var.environment}-tasks"
  }
}

resource "kubernetes_namespace" "aws_observability" {
  metadata {
    annotations = {
      name = "aws-observability"
    }

    name = "aws-observability"
  }
}

resource "kubernetes_config_map" "aws_observability" {
  metadata {
    name      = "aws-logging"
    namespace = kubernetes_namespace.aws_observability.metadata[0].name
  }

  data = {
    "output.conf" = <<EOF
[OUTPUT]
    Name cloudwatch_logs
    Match   *
    region ${data.aws_region.current.region}
    log_group_name ${module.eks.cluster_name}-eks
    log_stream_prefix ${var.environment}
    auto_create_group true
      EOF
  }
}
