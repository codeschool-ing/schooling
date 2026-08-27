package notify

import (
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"
)

/* What the provider tells us afterwards.

   # THE SECRET IS IN THE PATH, AND THE PATH IS NOT LOGGED

   Brevo posts these as a plain request with no signature — no HMAC, nothing to
   verify the body against. An open endpoint that marks addresses as refused is
   a denial of service against anybody's mail: find the URL, post somebody's
   address, and this platform stops writing to them.

   So the address carries a secret segment, compared in constant time. And
   `web.Logger` redacts everything under this prefix, because a secret in a path
   is a secret in Cloud Logging otherwise — which is where it would have gone,
   quietly, on the first delivery.

   The payment gateway's webhooks arrive at the same prefix for the same reason,
   and will find the arrangement already made.

   # IT ANSWERS 200 TO ALMOST EVERYTHING

   A provider retries what it did not hear back from. An event we ignore on
   purpose — a delivery, an open, a soft bounce — is not a failure, and
   answering anything else would buy a retry loop for a message saying "yes,
   thank you, we do not care about that one". What gets a 4xx is a bad secret and
   a body that is not JSON; what gets a 5xx is a database that would not answer,
   because that IS worth retrying. */

// Event is the part of a provider's payload this platform reads. Everything
// else in it is the provider's business.
type Event struct {
	Event string `json:"event"`
	Email string `json:"email"`
}

/*
permanent maps a provider's word to ours, and answers false for everything else.

	UNSUBSCRIBING IS DELIBERATELY NOT HERE. It is a marketing preference, and
	this platform's mail is a confirmation link and a staff invitation — refusing
	to send somebody the link that proves they own their own address, because
	they once opted out of a newsletter that does not exist, would be obeying an
	instruction nobody gave.

	NEITHER IS A SOFT BOUNCE, for the reason `ErrNotPermanent` gives.
*/
func permanent(event string) (Reason, bool) {
	switch strings.ToLower(strings.TrimSpace(event)) {
	case "hard_bounce", "hardbounce":
		return HardBounce, true
	case "blocked":
		return Blocked, true
	case "spam", "complaint":
		return Complaint, true
	}
	return "", false
}

/*
Hook is the endpoint the provider posts to.

	THE SECRET IS AN ARGUMENT AND NOT A PACKAGE VARIABLE, so that a deployment
	without one cannot accidentally mount an open endpoint: `cmd/api` mounts this
	only when it has a secret to mount it with.
*/
func Hook(secret string, list *Suppressions, log *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		/* CONSTANT TIME, because the alternative leaks the secret one byte at a
		   time to anybody willing to measure. It costs nothing here and the
		   habit is worth more than the microseconds. */
		given := r.PathValue("secret")
		if subtle.ConstantTimeCompare([]byte(given), []byte(secret)) != 1 {
			http.Error(w, "no", http.StatusNotFound)
			return
		}

		/* A CAP ON THE BODY. Nothing about this endpoint's address is a secret
		   once it is known, and an unbounded read is a way to spend this
		   process's memory from outside. A real payload is under a kilobyte. */
		raw, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			http.Error(w, "unreadable", http.StatusBadRequest)
			return
		}

		events, err := decode(raw)
		if err != nil {
			log.Warn("a delivery event that is not JSON", "error", err)
			http.Error(w, "not json", http.StatusBadRequest)
			return
		}

		for _, e := range events {
			why, refused := permanent(e.Event)
			if !refused {
				continue
			}

			first, err := list.Bar(r.Context(), e.Email, why)
			switch {
			case errors.Is(err, ErrNoAddress):
				// An event about nobody. The provider sends these for a request
				// that never had a recipient; there is nothing to record and
				// nothing wrong.
				continue
			case err != nil:
				/* THE ONLY 5XX HERE, and it is the one worth retrying: the
				   provider will come back, and the alternative is losing a
				   refusal because the database blinked. */
				log.Error("recording a refused address", "error", err, "event", e.Event)
				http.Error(w, "try again", http.StatusInternalServerError)
				return
			}

			/* THE ADDRESS IS NOT IN THIS LINE. The list holds a hash precisely
			   so that it holds no address, and a log that carried one would put
			   back exactly what the table went out of its way not to keep. */
			if first {
				log.Info("an address refused our mail", "reason", why)
			}
		}

		w.WriteHeader(http.StatusOK)
	})
}

/*
decode reads one event or a batch of them.

	BOTH SHAPES, because a provider that sends one today may batch tomorrow, and
	the failure of guessing wrong is silent: a body that does not fit is a
	refusal nobody records. The array is tried second because a single object is
	what arrives now.
*/
func decode(raw []byte) ([]Event, error) {
	var one Event
	if err := json.Unmarshal(raw, &one); err == nil {
		return []Event{one}, nil
	}

	var many []Event
	if err := json.Unmarshal(raw, &many); err != nil {
		return nil, err
	}
	return many, nil
}
