provider "google" {
  project = "mimetic-fulcrum-428802-f2"
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
    email  = "69532362936-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      sudo useradd -m -s /bin/bash bandi
      echo 'bandi:bandi' | sudo chpasswd
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config
      sudo systemctl restart sshd
      sudo -u bandi ssh-keygen -t rsa -b 4096 -f /home/bandi/.ssh/id_rsa_jumpserver -N ''
      sudo apt-get update
      sudo apt-get install -y sshpass
      sudo -u bandi sshpass -p 'test' ssh-copy-id -i /home/bandi/.ssh/id_rsa_jumpserver.pub testuser@34.27.69.229
      sudo -u bandi sshpass -p 'prod' ssh-copy-id -i /home/bandi/.ssh/id_rsa_jumpserver.pub produser@23.251.144.249
      echo 'Host test-server\n  Hostname 34.27.69.229\n  User testuser\n  IdentityFile ~/.ssh/id_rsa_jumpserver' | sudo tee -a /home/bandi/.ssh/config
      echo 'Host prod-server\n  HostName 23.251.144.249\n  User produser\n  IdentityFile ~/.ssh/id_rsa_jumpserver' | sudo tee -a /home/bandi/.ssh/config
      sudo chown bandi:bandi /home/bandi/.ssh/config
      sudo chmod 600 /home/bandi/.ssh/config
    EOT
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
    email  = "69532362936-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      sudo useradd -m -s /bin/bash prod-user
      echo 'prod-user:prod' | sudo chpasswd
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config
      sudo systemctl restart sshd
    EOT
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
    email  = "69532362936-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "lb-health-check"]

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      sudo useradd -m -s /bin/bash test-user
      echo 'test-user:test' | sudo chpasswd
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sudo sed -i 's/^Include /etc/ssh/sshd_config.d/*.conf/#Include /etc/ssh/sshd_config.d/*.conf/' /etc/ssh/sshd_config
      sudo systemctl restart sshd
    EOT
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
