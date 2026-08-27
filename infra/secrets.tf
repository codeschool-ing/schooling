/* The containers, and never what goes in them.

   A `google_secret_manager_secret_version` here would mean the value passing
   through Terraform — into the plan output, into the state file, into every
   version of that state the bucket keeps. The point of a secret manager is that
   the secret has exactly one home; a copy in a state bucket is a second one,
   and it is the copy nobody remembers to rotate.

   So this declares that the secret EXISTS and who may read it. What it says is
   written once by a person, and read by the service at start-up. */
resource "google_secret_manager_secret" "database_url" {
  secret_id = "schooling-database-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

/* The mail provider's key, in a container this file does not fill.

   SAME ARRANGEMENT AS THE DATABASE URL AND FOR THE SAME REASON: a
   `secret_version` here would put the value in the plan, in the state, and in
   every version of the state the bucket keeps.

   IT IS CREATED WHETHER OR NOT ANYTHING SENDS MAIL. An empty container costs
   nothing, and a service that names a secret which does not exist fails to
   start — so the container existing first is what makes turning mail on a
   matter of writing one value rather than a Terraform run. */
resource "google_secret_manager_secret" "mail_api_key" {
  secret_id = "schooling-mail-api-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

/* And the delivery hook's password.

   NOTHING SIGNS A DELIVERY EVENT — there is no HMAC over the body — so a shared
   secret is all there is between our endpoint and anybody who finds it. It
   travels as the password half of an HTTP Basic credential, which the provider's
   webhook form offers; it travelled in the path first, because nobody had opened
   that form.

   IT IS A SECRET AND `mail_hook_user` IS NOT, and they are split for that
   reason: a `tfvars` file is a file on somebody's laptop and in a plan's output,
   and a name belongs there while a password does not.

   Empty mounts no endpoint at all, which is the right failure — nothing there,
   rather than something anybody may post to. */
resource "google_secret_manager_secret" "mail_hook_password" {
  secret_id = "schooling-mail-hook-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

/* And the payment gateway's key, in a container this file does not fill either.

   IT IS THE ONE SECRET HERE THAT MOVES MONEY. The others read a database and
   send mail; this one creates charges against an account somebody withdraws
   from. So the key written into it is generated WITHOUT the withdrawal
   permission the provider offers — the platform receives and never sends, and a
   key that cannot pay anybody out is a leak that costs an audit rather than a
   balance. That is a property of the key and not of this file, which is why it
   is written down here: nothing in Terraform can check it.

   ONE CONTAINER FOR THE SANDBOX AND THE LIVE ACCOUNT BOTH. They are different
   keys against different hosts, and which one is in here is which environment
   this project is — a second container named `-sandbox` would be a value that
   has to agree with `SCHOOLING_ENV`, and two settings that must agree are one
   setting with a way to be wrong.

   Empty mounts no gateway at all, which is the right failure: no checkout,
   rather than a checkout that cannot take money and does not say so. */
resource "google_secret_manager_secret" "asaas_key" {
  secret_id = "schooling-asaas-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

/* And the token the gateway presents when it posts an event.

   IT IS A SEPARATE SECRET FROM THE KEY ABOVE, and the split is the same one the
   mail key and the mail hook's password already have: they authenticate
   opposite directions. The key is what we present to them; this is what they
   present to us, it is generated on their webhook form rather than ours, and
   rotating either has nothing to do with the other.

   WHAT AN OPEN ENDPOINT WOULD BUY IS WORSE HERE THAN AT THE MAIL HOOK. Nothing
   signs a payment event, so this token is the whole of the guard — and a forged
   event saying a charge was paid opens a subscription nobody paid for.

   Empty mounts no endpoint at all, which is the right failure: a checkout that
   takes money and hears nothing back is a visible state, and an endpoint
   anybody may post to is not. */
resource "google_secret_manager_secret" "asaas_hook_token" {
  secret_id = "schooling-asaas-hook-token"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}
