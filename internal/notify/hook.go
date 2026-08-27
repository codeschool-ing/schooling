package notify

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"
)

/* What the provider tells us afterwards.

   # THE CREDENTIAL IS IN A HEADER, AND IT USED TO BE IN THE PATH

   Nothing about a delivery event is self-authenticating: there is no signature
   over the body, so the only thing between our endpoint and anybody who finds
   it is a shared secret. An open endpoint that marks addresses as refused is a
   denial of service against anybody's mail — post somebody's address and this
   platform stops writing to them.

   The first version put that secret in the path, on the belief that the
   provider offered nothing better. THAT BELIEF WAS WRONG, and it was written
   into four files in capital letters before anybody opened the provider's own
   form, which offers HTTP Basic. So the secret moved to where a secret belongs.

   WHAT MOVING IT BOUGHT is three places it no longer appears: the request log
   (`web.Logger` writes `r.URL.Path` on every request), the address bar of
   whoever configures it, and a screenshot of that screen — which is how
   sixteen characters of the old one ended up in a chat transcript.

   BASIC AND NOT THE PROVIDER'S OWN "TOKEN". Basic is `Authorization: Basic
   base64(user:password)` and means the same everywhere; the other is a header
   whose name and shape are the provider's to change, and designing against an
   unverified guess about what a provider sends is precisely the mistake this
   file is correcting.

   `web.Loggable` still redacts everything under `/hooks/`, though nothing
   secret is in the path any more. The payment gateway's webhooks arrive at the
   same prefix, the guarantee costs nothing, and the change that removed it
   would be the one somebody later put a secret back into a path under.

   # IT ANSWERS 200 TO ALMOST EVERYTHING

   A provider retries what it did not hear back from. An event we ignore on
   purpose — a delivery, an open, a soft bounce — is not a failure, and
   answering anything else would buy a retry loop for a message saying "yes,
   thank you, we do not care about that one". What gets a 4xx is a bad
   credential and a body that is not JSON; what gets a 5xx is a database that
   would not answer, because that IS worth retrying. */

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
	case "invalid", "invalid_email":
		return Invalid, true
	}
	return "", false
}

/*
Hook is the endpoint the provider posts to.

	THE CREDENTIAL IS AN ARGUMENT AND NOT A PACKAGE VARIABLE, so that a
	deployment without one cannot accidentally mount an open endpoint: `cmd/api`
	mounts this only when it has one to mount it with.

	`user` and `password` are one credential in two halves, because that is the
	shape Basic has. Neither means anything alone and the comparison is over
	both at once.
*/
func Hook(user, password string, list *Suppressions, log *slog.Logger) http.Handler {
	want := credential(user, password)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !authorised(r.Header.Get("Authorization"), want) {
			/* 401 AND NOT 404, WHICH IS THE OPPOSITE OF WHAT THE PATH VERSION
			   ANSWERED, and the reversal is the point rather than a change of
			   taste. A path carrying a secret had to answer as though the
			   address did not exist, because "this is here and you may not have
			   it" tells a scanner they have found it and need only the secret.
			   The address is public now — it is in this repository — so hiding
			   it buys nothing, and 401 is the truthful answer that also tells
			   the provider its CREDENTIAL is wrong rather than its URL. */
			w.Header().Set("WWW-Authenticate", `Basic realm="hooks"`)
			http.Error(w, "no", http.StatusUnauthorized)
			return
		}

		/* A CAP ON THE BODY. An unbounded read is a way to spend this process's
		   memory from outside, and it is read AFTER the credential is checked so
		   that spending it requires holding one. A real payload is under a
		   kilobyte. */
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
credential is the header value a correct request carries, worked out once.

	IT IS HASHED RATHER THAN KEPT AS A STRING, so that the comparison below is
	between two values of the same fixed length. Comparing the headers
	themselves in constant time still leaks their LENGTH —
	`subtle.ConstantTimeCompare` refuses outright when the two differ — and a
	length is the first thing a guesser would like to be told.

	This is not password storage, and the hash protects nothing at rest: the
	credential is in this process's memory either way. It is here to make the
	comparison say nothing.
*/
func credential(user, password string) [sha256.Size]byte {
	return sha256.Sum256([]byte("Basic " +
		base64.StdEncoding.EncodeToString([]byte(user+":"+password))))
}

// authorised compares what arrived against what was expected, in constant time
// and without regard to length.
func authorised(given string, want [sha256.Size]byte) bool {
	got := sha256.Sum256([]byte(strings.TrimSpace(given)))
	return subtle.ConstantTimeCompare(got[:], want[:]) == 1
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
