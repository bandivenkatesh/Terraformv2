provider "google" {
  project = "peerless-list-427614-f1"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "jump_server" {
  name         = "jump-server"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240614"
      size  = 10
      type  = "pd-balanced"
    }
    auto_delete = true
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = "90498651909-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    goog-ec-src = "vm_add-gcloud"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

resource "google_compute_instance" "prod_server" {
  name         = "prod-server"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240614"
      size  = 10
      type  = "pd-balanced"
    }
    auto_delete = true
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = "90498651909-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    goog-ec-src = "vm_add-gcloud"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

resource "google_compute_instance" "test_server" {
  name         = "test-server"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240614"
      size  = 10
      type  = "pd-balanced"
    }
    auto_delete = true
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = "90498651909-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    goog-ec-src = "vm_add-gcloud"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

resource "null_resource" "generate_ssh_keys" {
  provisioner "local-exec" {
    command = <<EOT
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_jumpserver -N ''
    EOT
  }
}

resource "null_resource" "configure_jump_server" {
  depends_on = [google_compute_instance.jump_server, null_resource.generate_ssh_keys]

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash bandi",
      "echo 'bandi:bandi' | sudo chpasswd",
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd",
      "sudo -u bandi ssh-keygen -t rsa -b 4096 -f /home/bandi/.ssh/id_rsa_jumpserver -N ''",
      "sudo apt-get update",
      "sudo apt-get install -y sshpass",
      "sudo -u bandi sshpass -p 'test' ssh-copy-id -i /home/bandi/.ssh/id_rsa_jumpserver.pub testuser@${google_compute_instance.test_server.network_interface.0.access_config.0.nat_ip}",
      "sudo -u bandi sshpass -p 'pass' ssh-copy-id -i /home/bandi/.ssh/id_rsa_jumpserver.pub produser@${google_compute_instance.prod_server.network_interface.0.access_config.0.nat_ip}",
      "echo 'Host test-server\n  Hostname ${google_compute_instance.test_server.network_interface.0.access_config.0.nat_ip}\n  User testuser\n  IdentityFile ~/.ssh/id_rsa_jumpserver' | sudo tee -a /home/bandi/.ssh/config",
      "echo 'Host prod-server\n  HostName ${google_compute_instance.prod_server.network_interface.0.access_config.0.nat_ip}\n  User produser\n  IdentityFile ~/.ssh/id_rsa_jumpserver' | sudo tee -a /home/bandi/.ssh/config",
      "sudo chown bandi:bandi /home/bandi/.ssh/config",
      "sudo chmod 600 /home/bandi/.ssh/config"
    ]

    connection {
      type        = "ssh"
      user        = "your-ssh-username"
      private_key = file("~/.ssh/id_rsa_jumpserver")
      host        = google_compute_instance.jump_server.network_interface.0.access_config.0.nat_ip
    }
  }
}

resource "null_resource" "configure_prod_server" {
  depends_on = [google_compute_instance.prod_server, null_resource.generate_ssh_keys]

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash prod-user",
      "echo 'prod-user:pass' | sudo chpasswd",
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]

    connection {
      type        = "ssh"
      user        = "your-ssh-username"
      private_key = file("~/.ssh/id_rsa_jumpserver")
      host        = google_compute_instance.prod_server.network_interface.0.access_config.0.nat_ip
    }
  }
}

resource "null_resource" "configure_test_server" {
  depends_on = [google_compute_instance.test_server, null_resource.generate_ssh_keys]

  provisioner "remote-exec" {
    inline = [
      "sudo useradd -m -s /bin/bash test-user",
      "echo 'test-user:test' | sudo chpasswd",
      "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]

    connection {
      type        = "ssh"
      user        = "your-ssh-username"
      private_key = file("~/.ssh/id_rsa_jumpserver")
      host        = google_compute_instance.test_server.network_interface.0.access_config.0.nat_ip
    }
  }
}
