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

  /* `activation_policy` IS LEFT TO WHOEVER STOPS THE INSTANCE, NOT TO THIS FILE.

     After the move this instance is stopped by hand and kept for a week as
     the way back, and only then deleted. Stopped means `activation_policy =
     NEVER`, set outside Terraform. Nothing above says ALWAYS, and it does not
     need to: the provider fills an absent value in as ALWAYS. So the first
     apply for any reason during that week would propose `NEVER -> ALWAYS`,
     in place, and restart the instance, billing it again and putting a
     second writable copy of the data back on the network.

     aleogr/lab found this on the shared instance itself
     (`gcp/terraform/instance.tf`). It first left the field out on the theory
     that unset means unmanaged, and a plan against a stopped instance
     proposed waking it every time. This is the fix it arrived at.

     The trade is the same as there. Terraform never sets this field again in
     either direction, so an instance somebody stopped and forgot stays
     stopped. Here that is the point: while this instance exists, only a
     person decides whether it runs. */
  lifecycle {
    ignore_changes = [settings[0].activation_policy]
  }

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

/* THE DATABASE ON THE SHARED INSTANCE, which is where the data is going.

   `lab-postgres` in `aleogr-lab-shared-dacd` belongs to aleogr/lab, and this
   configuration never declares it. What is declared here is the one database
   inside it that is this project's. The shared project lets this project in:
   `schooling-run` holds `roles/cloudsql.client` there and `schooling-deploy`
   holds `roles/cloudsql.viewer`, granted from aleogr/lab. This resource is
   created by whoever applies this configuration, which is the owner's own
   user, and that user already has the rights on the shared project.

   The project and the instance are literals, like `DATABASE_CONNECTION` in
   `release.yml`. They are not taken from `var.database_instances`: that is a
   list of what gets MOUNTED, and picking an entry out of it would be a join by
   position.

   ABANDON, AND HERE IT IS NOT OPTIONAL AT ALL.

   On this project's own instance, ABANDON was the second fence, because
   `deletion_protection` guards the instance around it. On the shared
   instance there is no first fence of ours. The instance's protection is
   aleogr/lab's to set, and it protects the INSTANCE. Dropping one database
   inside it deletes no instance, so nothing there would stop it.

   With the default, DELETE, removing this block drops `schooling` and every
   row in it, on an instance that goes on serving another project as if
   nothing happened. So would renaming it in a way Terraform reads as a
   replacement, or moving it to another file carelessly. ABANDON makes all of
   those Terraform forgetting a database it can import again. */
resource "google_sql_database" "shared" {
  project  = "aleogr-lab-shared-dacd"
  instance = "lab-postgres"
  name     = "schooling"

  deletion_policy = "ABANDON"
}

/* THERE IS NO `google_sql_user` HERE, AND THAT IS THE DESIGN.

   Terraform would need the password in order to set it, which would put it in
   the state file — a bucket, readable by anybody who can read the bucket,
   backed up in every version of that state forever. The roadmap says Terraform
   owns the secret CONTAINERS; the values are not its business.

   So the role is created once by hand and the URL written into the secret this
   configuration made for it. `infra/README.md` has the two commands. */
