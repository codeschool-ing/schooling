/* One Postgres instance, and the database inside it.

   IT DOES NOT SCALE TO ZERO. Cloud Run costs nothing while nobody is reading;
   this runs whether or not anybody does, and it is the whole standing cost of
   the project. That is the trade for a managed database with backups and
   point-in-time recovery, and it is worth stating in the file rather than
   discovering it on an invoice.

   REACHED THROUGH THE CONNECTOR AND NOT OVER THE NETWORK. There are no
   authorised networks: nothing can open a socket to this instance from the
   internet, whatever it knows. Cloud Run reaches it through a unix socket the
   platform mounts, and a person reaches it through the Auth Proxy — both of
   which are IAM decisions rather than a password that leaked once and works
   forever. */
resource "google_sql_database_instance" "main" {
  name             = "schooling"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    /* THE EDITION IS SAID OUT LOUD, and leaving it out is what broke the first
       apply. Unset, the API picked ENTERPRISE_PLUS — where shared-core tiers do
       not exist at all — and refused `db-f1-micro` with a message suggesting
       `db-perf-optimized-N-*`, which is a minimum of two dedicated vCPUs and
       several times the bill this project agreed to.

       The tier and the edition are one decision and the API will make the half
       nobody wrote down. */
    edition           = "ENTERPRISE"
    tier              = var.database_tier
    availability_type = "ZONAL"
    disk_size         = 10
    disk_autoresize   = true

    /* THE ROADMAP ASKS FOR A BACKUP THAT HAS BEEN RESTORED, and this is only
       the half that can be declared. Backups configured are not backups
       proven — what is written here is a belief until something reads the
       bytes back.

       `tools/restore-drill/restore-drill.sh` is the other half: it clones this
       instance from the transaction log onto a new one, compares the two
       schemas and every row count, and destroys the clone. Never over the live
       instance, because the restore is itself the destructive operation. Run
       it after anything that changes this block. */
    backup_configuration {
      enabled                        = true
      start_time                     = "07:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"
    }
  }

  /* ON BY DEFAULT, AND THE FRICTION IS THE POINT. `terraform destroy` on a
     configuration that owns a database is one command away from being the
     worst afternoon of the project. Turning this off is a commit somebody can
     see. */
  deletion_protection = true

  depends_on = [google_project_service.enabled]
}

resource "google_sql_database" "schooling" {
  name     = "schooling"
  instance = google_sql_database_instance.main.name

  /* ABANDON, NOT DELETE — and the default is DELETE.

     The INSTANCE is protected and the database inside it was not: removing
     this block, or renaming it in a way Terraform reads as a replacement,
     would drop the database and every row in it while leaving the instance
     standing. The protection one level up does not reach here, because
     dropping a database is not deleting the instance.

     `ABANDON` makes Terraform stop managing it instead. Losing track of a
     database is a bad afternoon; dropping one is the end of the project's
     data, and the two are one attribute apart. */
  deletion_policy = "ABANDON"
}

/* THERE IS NO `google_sql_user` HERE, AND THAT IS THE DESIGN.

   Terraform would need the password in order to set it, which would put it in
   the state file — a bucket, readable by anybody who can read the bucket,
   backed up in every version of that state forever. The roadmap says Terraform
   owns the secret CONTAINERS; the values are not its business.

   So the role is created once by hand and the URL written into the secret this
   configuration made for it. `infra/README.md` has the two commands. */
