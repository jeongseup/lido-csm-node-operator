# terraform/modules/gcp/firewall/main.tf

// 3. 방화벽 규칙 설정
// 3-1. IAP를 통한 SSH 접속 허용 (가장 중요한 보안 규칙!)
// source_ranges에 GCP의 IAP IP 대역인 "35.235.240.0/20"를 지정해야 합니다.
// 이렇게 하면 오직 IAP를 통해서만 SSH(22번 포트) 접근이 가능해집니다.
resource "google_compute_firewall" "allow_ssh_via_iap" {
  project = var.project_id
  name    = "${var.network_name}-allow-ssh-via-iap"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP's official IP range
  target_tags   = var.target_tags
}

resource "google_compute_firewall" "allow_egress" {
  project = var.project_id
  name    = "${var.network_name}-allow-all-egress"
  network = var.network_name

  allow {
    protocol = "all"
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
}
