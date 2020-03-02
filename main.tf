#variable "hosts" {
 # default = {
   # "0" = "flask-ansible.sxvova.opensource-ukraine.org"
   # "1" = "gitlab.ashmrkvch.opensource-ukraine.org"
 # }
#}

variable "flask" {
  type = list(object({
    credenrials  
    projects_id 
    host       
    path       
    port      
    }))
  default = [
    {
     credentials = "${file("flask_key.json")}"
     project_id = "devops-259416"
     host = "flask-ansible.sxvova.opensource-ukraine.org"
     path = "/help"
     port = "5000"
    }
  ]
}

variable "sentry" {
  type = list(object({
    credenrials  
    projects_id 
    host       
    path       
    port      
    }))
  default = [
    {
     #потом добавлю
    }
  ]
}

variable "projects"{
    default = [
        {
            concat(flask, sentry)
        }
    ]
}


provider "google" {
  credentials = "${file("flask_key.json")}"
  project     = "devops-259416"
  region      = "us-central1"
  zone        = "us-central1-c"
}

resource "google_monitoring_uptime_check_config" "http" {
  display_name = "HTTP UPTIME CHECK"
  count     = "${length(var.hosts)}"
  timeout = "10s"
  period = "60s"
  http_check {
    path = "/help"
    port = "5000"
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
      host = "${var.hosts[count.index]}"
    }
  }
}

resource "google_monitoring_uptime_check_config" "tcp_group" {
  display_name = "TCP UPTIME CHECK"
  timeout      = "60s"

  tcp_check {
    port = 5000
  }

   monitored_resource {
    type = "uptime_url"
    labels = {
      host = "flask-ansible.sxvova.opensource-ukraine.org"
    }
  }
}

resource "google_monitoring_uptime_check_config" "https" {
  display_name = "HTTPS UPTIME CHECK"
  timeout = "10s"
  period = "60s"
   http_check {
    path = "/help"
    port = "5000"
    use_ssl = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host = "flask-ansible.sxvova.opensource-ukraine.org"
    }
  }
}


resource "google_monitoring_notification_channel" "flask" {
  display_name = "Flask Notification Channel"
  type         = "email"
  labels = {
    email_address = "shemrikovych@gmail.com"
  }
}

output "flask_id" {
  value = "${google_monitoring_notification_channel.flask.name}"
}

locals {
  flask_id = "${google_monitoring_notification_channel.flask.name}"
}
resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "Flask Alert Policy"
  combiner     = "OR"
  conditions {
    display_name = "test condition"
    condition_threshold {
     filter     = "metric.type=\"compute.googleapis.com/instance/disk/write_bytes_count\" AND resource.type=\"gce_instance\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }     
    }  
  }
  notification_channels = [
       "${local.flask_id}"
  ]
}

