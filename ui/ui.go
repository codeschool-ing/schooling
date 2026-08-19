// Package ui carries the study interface into the binary and serves it.
//
// # ONE ORIGIN (P-03)
//
// The same process answers the API and serves the interface, which is what
// removes CORS entirely and lets the session cookie be HttpOnly — the token
// never touches JavaScript. It also removes the static host, and with it the
// edge cache that handed the predecessor's browser one module from before a
// deploy and another from after.
//
// It is called `ui` rather than `web` because `internal/platform/web` is the
// HTTP plumbing, and two packages called the same thing in one binary is a
// filename question every reader has to answer twice.
//
// # THE ROUTES ARE FRAGMENTS, NOT PATHS
//
// `#/course/web-fundamentals`, not `/course/web-fundamentals`. That is not a
// preference: the offline bundle is a roadmap item, and a single file opened
// from `file://` has no server to fall back to — History API routing simply
// does not work there. Choosing fragments now means the bundle is a packaging
// job later rather than a second router.
//
// It also means this package has no catch-all. An unknown path is a 404, which
// is what it is, instead of the shell rendering itself and a student staring at
// an empty screen wondering what they typed wrong.
//
// # THE ONE REAL PATH
//
// `/verify/<code>` is served the shell, because that address is PRINTED ON A
// CERTIFICATE and read by somebody who is checking a stranger's claim. A `#` in
// it would survive being clicked and not being retyped. It is one named
// exception rather than a fallback, and it is here rather than in the router by
// accident.
package ui

import (
	"embed"
	"mime"
	"net/http"
	"strings"
)

//go:embed index.html assets
var files embed.FS

// `.woff2` IS NOT IN GO'S BUILT-IN TABLE. On a developer's machine it resolves
// anyway, out of /etc/mime.types — and the deployed image is a scratch
// container that has no such file, so the fonts would go out as
// application/octet-stream in the one place it matters and nowhere a person
// would notice. Registering it is cheaper than the afternoon that costs.
func init() {
	if err := mime.AddExtensionType(".woff2", "font/woff2"); err != nil {
		panic("ui: the woff2 media type is not a media type: " + err.Error())
	}
}

// Handler serves the interface.
//
// `version` stamps every asset's ETag. THAT IS THE WHOLE CACHING STRATEGY, and
// it is chosen against the defect the predecessor actually had: with no build
// step there are no hashed filenames, so instead every file revalidates and
// every file's validator is the build. A deploy invalidates all of them at
// once, and there is no arrangement of caches that can serve one file from
// before it and another from after.
//
// AN EMPTY VERSION MEANS NO CACHING AT ALL, and that rule falls out of the
// strategy rather than being a development convenience bolted onto it: a
// binary that cannot say which build it is has no honest validator to offer,
// so it does not offer one. Passing the unstamped `dev` through would be worse
// than useless — every unstamped build shares that string, so a browser holds
// the first CSS it ever saw and revalidates it successfully against every
// later one. That is not a hypothetical; it is what this handler did on its
// first run, and the edit that fixed it was invisible until the cache was
// cleared.
func Handler(version string) http.Handler {
	// The shell is written out rather than served as a file, and that is not an
	// optimisation. `http.FileServer` answers a request for `index.html` with a
	// 301 to `./` — sensible for a directory listing, wrong for the one document
	// this application has, and it turns every cold load into two round trips
	// before anything renders.
	shell, err := files.ReadFile("index.html")
	if err != nil {
		// The embed is a compile-time fact; this cannot happen at run time.
		panic("ui: the embedded interface cannot be read: " + err.Error())
	}

	static := http.FileServerFS(files)
	etag := `"` + version + `"`

	// Revalidate, always, and the validator is the build. `no-cache` does not
	// mean "do not cache" — it means "ask first", which is exactly the contract
	// that makes a half-old deploy impossible.
	//
	// It answers whether the response is finished, which it is on a 304.
	stamp := func(w http.ResponseWriter, r *http.Request) bool {
		if version == "" {
			w.Header().Set("Cache-Control", "no-store")
			return false
		}

		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("ETag", etag)
		if match := r.Header.Get("If-None-Match"); match != "" && strings.Contains(match, etag) {
			w.WriteHeader(http.StatusNotModified)
			return true
		}
		return false
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/")

		switch {
		case strings.HasPrefix(path, "assets/"):
			if stamp(w, r) {
				return
			}
			static.ServeHTTP(w, r)

		case path == "", path == "index.html", strings.HasPrefix(path, "verify/"):
			// The last of those is the address printed on a certificate; the
			// code after it is read by the interface out of the URL.
			if stamp(w, r) {
				return
			}
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
			_, _ = w.Write(shell)

		default:
			http.NotFound(w, r)
		}
	})
}
