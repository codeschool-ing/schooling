/* The service, and the job that migrates before it.

   # TERRAFORM NEVER MANAGES THE IMAGE

   Which revision runs is the deploy pipeline's, and this file's `ignore_changes`
   is what makes that true rather than agreed. Without it every `terraform apply`
   would roll the service back to whatever image this configuration last knew
   about — which is the placeholder below, and which nobody would notice until
   an apply for an unrelated reason quietly undeployed a week of work.

   The placeholder exists because a service must have SOMETHING to start before
   there is an image to give it. It is Google's own hello container, it is
   replaced by the first deploy, and it is never looked at again. */

/* TWO IMAGES AND NOT ONE. `deploy/local/Dockerfile` builds a single binary
   chosen by a build argument, so the API and the migration are separate images
   sharing every layer up to the compile. Neither name is ever pushed by
   Terraform — they are here so the pipeline and this configuration cannot
   disagree about where an image goes. */
locals {
  registry = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.images.repository_id}"
  api      = "${local.registry}/api"
  migrate  = "${local.registry}/migrate"
}

/* THE MIGRATION IS A JOB AND NOT A STEP IN THE CONTAINER'S START-UP.

   Run at start-up it would run once per instance, concurrently, on every scale
   event — which is what the advisory lock in `cmd/migrate` exists to survive,
   but surviving a stampede is not the same as not causing one. As a job it runs
   ONCE, to completion, and the pipeline waits for it before sending traffic to
   the new revision: a schema that has not been applied is a deploy that has not
   happened. */
resource "google_cloud_run_v2_job" "migrate" {
  name     = "schooling-migrate"
  location = var.region

  /* OFF, AND SAID OUT LOUD. The provider turns this on by default, and on
     something stateless it protects nothing while blocking the one operation
     that is routinely needed: replacing a resource whose creation failed.
     Terraform marks such a resource tainted and replaces it on the next apply,
     which this flag then refuses — so a failed create becomes a deadlock that
     is cleared by editing the configuration.

     What is worth protecting here is the database, and it is: the instance
     carries `deletion_protection` and the database inside it is ABANDON. This
     holds no data, keeps its URL across a replacement, and is rebuilt in
     seconds. */
  deletion_protection = false


  template {
    template {
      service_account = google_service_account.run.email
      max_retries     = 0

      /* No `command`: the image's entrypoint IS the migration binary. An
         override here would be this file holding an opinion about the inside
         of an image it does not build. */
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"

        env {
          name  = "SCHOOLING_ENV"
          value = "production"
        }
        env {
          name  = "SCHOOLING_PLATFORM_DOMAIN"
          value = var.platform_domain
        }
        env {
          name = "SCHOOLING_DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.database_url.secret_id
              version = "latest"
            }
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_project_service.enabled]
}

resource "google_cloud_run_v2_service" "api" {
  name     = "schooling"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  /* OFF, AND SAID OUT LOUD. The provider turns this on by default, and on
     something stateless it protects nothing while blocking the one operation
     that is routinely needed: replacing a resource whose creation failed.
     Terraform marks such a resource tainted and replaces it on the next apply,
     which this flag then refuses — so a failed create becomes a deadlock that
     is cleared by editing the configuration.

     What is worth protecting here is the database, and it is: the instance
     carries `deletion_protection` and the database inside it is ABANDON. This
     holds no data, keeps its URL across a replacement, and is rebuilt in
     seconds. */
  deletion_protection = false


  template {
    service_account = google_service_account.run.email

    /* SCALES TO ZERO, which is what makes an idle deployment cost nothing and
       is the reason the database is the only standing bill. The ceiling is low
       on purpose: it is a limit on the damage a loop can do to the invoice,
       not a capacity plan. */
    scaling {
      min_instance_count = 0
      max_instance_count = 4
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      /* IT IS PRODUCTION BECAUSE OF WHERE IT RUNS, not because of how finished
         it is. `development` here would take `Secure` off the session cookie on
         a public host — see `cmd/api/main.go`, where the flag is read. */
      env {
        name  = "SCHOOLING_ENV"
        value = "production"
      }
      env {
        name  = "SCHOOLING_PLATFORM_DOMAIN"
        value = var.platform_domain
      }
      env {
        name = "SCHOOLING_DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_project_service.enabled]
}

/* A SCHOOL IS A PUBLIC WEBSITE. The catalogue, the track maps and the first
   course of every track are the shop window (N-04) and are readable by somebody
   with no account at all, so the service itself is open and every door inside it
   is the application's own. */
resource "google_cloud_run_v2_service_iam_member" "anybody_may_read" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
