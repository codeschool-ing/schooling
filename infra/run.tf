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
  load     = "${local.registry}/load"
  analyse  = "${local.registry}/analyse"
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

/* THE CATALOGUE, FROM THE FILES INTO THE MIRROR.

   A SECOND JOB AND NOT A SECOND COMMAND IN THE FIRST ONE. The schema and the
   content fail differently and are rolled back differently: a migration that
   half-applied is a database in an unknown shape, a catalogue that did not pass
   its checks is a catalogue that was never written at all — `cmd/load`
   validates first and writes nothing if anything is wrong. Two concerns, two
   exit codes, two places to look.

   IT PRUNES. What the files no longer carry leaves the mirror, in the same
   transaction that writes what they do carry, because a course deleted from
   `content/` that kept serving would be visible to students and invisible in
   the repository.

   IT REFUSES A SCHOOL NOBODY CREATED. A directory in `content/` does not make a
   tenant — a school is also an address and a domain mapping — so the row is
   created once by hand and this fails until it is. See `infra/README.md`. */
resource "google_cloud_run_v2_job" "load" {
  name     = "schooling-load"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = google_service_account.run.email
      max_retries     = 0

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

        // Where the image keeps the files. See `deploy/Dockerfile`.
        args = ["/content"]

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

/* THE NIGHTLY ANALYSIS, WHICH SAID IT RAN ON A SCHEDULE AND DID NOT.

   `cmd/analyse` has described itself as a scheduled job since it was written —
   "it runs on a schedule, writes a rollup, and the console reads the rollup" —
   and nothing in this configuration ran it. There was no job and there was no
   scheduler. In production it had never run once.

   THAT IS WORSE THAN A REPORT NOBODY READS. This job does not only compute: it
   WITHDRAWS a question the strong students fail, audited, with the numbers that
   condemned it. Never running, every such question stayed in circulation and
   every student who met it was marked on our mistake — and the console's
   questions screen, which has its own screen for "the rollup was never made",
   would have shown that screen forever while looking like a feature working
   correctly.

   IT IS A JOB AND NOT A GOROUTINE IN THE API, for the reason the migration is:
   started inside the service it would run once per instance, on every scale
   event, and two of them sweeping at once is two audit entries for one
   withdrawal.

   `max_retries = 0` LIKE THE OTHERS. The sweep is idempotent, so a retry would
   be harmless — and a retry that runs an hour later is a second set of numbers
   for the same night, which is a report that disagrees with itself. A failed
   night is a failed night, and the screen already says when the rollup was
   made. */
resource "google_cloud_run_v2_job" "analyse" {
  name     = "schooling-analyse"
  location = var.region

  deletion_protection = false

  template {
    template {
      service_account = google_service_account.run.email
      max_retries     = 0

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

        /* NO ARGUMENTS. `cmd/analyse` takes one flag, `-window`, and its
           default is a year — which is the value this configuration would pass
           if it passed anything. A window written here would be a second place
           holding a number the command already decides, and the one that gets
           edited would be whichever the next person happens to open. */

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

  /* THE OTHER `scaling`, AND IT IS NOT THE ONE INSIDE `template`.

     Two blocks with the same name at two levels, and they are different
     features. The one below is the REVISION's autoscaler: how many instances
     of the running revision, between none and four. This one is the SERVICE's,
     added to the API later — a floor held across revisions, and a manual
     instance count for services that opt out of autoscaling altogether.

     IT IS WRITTEN HERE BECAUSE IT CAME BACK. Left out, the API filled it in
     with zeros, the provider read those zeros into state, and every plan then
     proposed removing a block nobody had written — `0 -> null`, applied
     successfully, and present again on the very next plan. That is the fifth
     entry in `infra/README.md`'s table of defaults nobody stated, and the
     first one whose whole cost is noise.

     Noise is the cost that matters here. A plan that always shows one change
     is a plan that stops being read, and the next change it shows — a database
     replacement, a service being destroyed — arrives in the same shrug.

     The zeros are what the service already is, so this changes no behaviour.
     `AUTOMATIC` and a floor of zero is what lets an idle deployment cost
     nothing; `manual_instance_count` is meaningless while the mode is
     automatic, and is stated because it is what the API reports and leaving it
     out is what started this. */
  scaling {
    scaling_mode          = "AUTOMATIC"
    min_instance_count    = 0
    manual_instance_count = 0
  }

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

      /* THE MAIL, AND ONLY ON THIS SERVICE.

         The three jobs beside it — migrate, load, analyse — send nothing to
         anybody. A key handed to a container that has no use for it is a key in
         one more place, and `cmd/analyse` in particular runs unattended at
         03:10 with nobody reading its environment.

         AN EMPTY KEY IS NOT A FAILURE TO THE APPLICATION. `cmd/api` wires
         `mail.Outbox` when there is none, keeps the messages it would have sent
         rather than dropping them, and says which of the two it chose in its
         start-up line.

         IT IS A FAILURE TO THE REVISION, THOUGH, AND THIS COMMENT SAID
         OTHERWISE. A `secret_key_ref` at `latest` is resolved when the instance
         starts, so a secret with NO version stops the revision coming up at all
         — `Secret projects/…/versions/latest was not found`, which is the same
         wall the database URL hits and the reason `infra/README.md` has a
         section called "Applying takes two passes".

         So the value goes in FIRST and this applies after. The empty container
         still earns its place: it is what a person writes into, and it has to
         exist before anybody can. */
      env {
        name  = "SCHOOLING_MAIL_FROM"
        value = var.mail_from
      }
      env {
        name  = "SCHOOLING_MAIL_REPLY_TO"
        value = var.mail_reply_to
      }
      env {
        name = "SCHOOLING_MAIL_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.mail_api_key.secret_id
            version = "latest"
          }
        }
      }

      /* AND WHAT THE PROVIDER HAS TO PRESENT TO BE HEARD.

         The two halves of an HTTP Basic credential. The NAME is a variable and
         the PASSWORD is a secret, which is the whole reason they are two
         things: a `tfvars` file is a file on somebody's laptop and in a plan's
         output, and a name belongs there.

         The password is subject to the same two-pass rule as the key above: a
         versionless secret named at `latest` stops the revision starting, so
         the value is written before this is applied.

         Empty mounts no endpoint. That is deliberate rather than tolerated —
         an open one is a way for anybody to stop this platform writing to an
         address of their choosing, so the failure of forgetting the value is
         "nothing is listening" rather than "everything is". */
      env {
        name  = "SCHOOLING_MAIL_HOOK_USER"
        value = var.mail_hook_user
      }
      env {
        name = "SCHOOLING_MAIL_HOOK_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.mail_hook_password.secret_id
            version = "latest"
          }
        }
      }

      /* AND WHAT THE PAYMENT GATEWAY IS TALKED TO WITH.

         Subject to the same two-pass rule as the two above, and it has already
         been through it: the container and its grant were applied first and the
         value written before this line existed, because a versionless secret
         named at `latest` stops the revision starting.

         EMPTY MOUNTS NO CHECKOUT AT ALL. `cmd/api` registers the route only
         when this has a value, so a deployment without one offers nobody a way
         to pay rather than a button that fails after they have decided to.

         WHICH HOST IT REACHES IS NOT HERE AND IS NOT A SETTING AT ALL. It is
         read off the key: a sandbox one says `$aact_hmlg_` and anything else
         goes live. That is what lets this service run the whole payment path
         against the sandbox before an account with real money exists — and
         `cmd/api` says so in the log when it does. */
      env {
        name = "SCHOOLING_ASAAS_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.asaas_key.secret_id
            version = "latest"
          }
        }
      }

      /* AND WHAT THAT GATEWAY PRESENTS WHEN IT POSTS AN EVENT.

         The other direction, and a separate secret for that reason. Same
         two-pass rule as everything above it: the value is written before this
         is applied, because a versionless secret at `latest` stops the revision
         starting.

         Empty mounts no endpoint. A checkout that takes money and hears nothing
         back is a state somebody can see; an endpoint anybody may post to,
         which would open subscriptions nobody paid for, is not. */
      env {
        name = "SCHOOLING_ASAAS_HOOK_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.asaas_hook_token.secret_id
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
