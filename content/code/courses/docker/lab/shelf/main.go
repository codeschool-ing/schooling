// shelf serves a bookshop's catalogue over HTTP. It is the program the docker
// course packages, lesson after lesson, so it is small on purpose: what is
// worth reading in it is how it behaves inside a container — it takes its
// configuration from the environment, logs to standard output, and stops
// cleanly when it is sent SIGTERM.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// version is stamped at build time with -ldflags "-X main.version=...".
var version = "dev"

type book struct {
	ID     int    `json:"id"`
	Title  string `json:"title"`
	Author string `json:"author"`
}

// The catalogue a shelf with no database serves.
var builtIn = []book{
	{1, "The Left Hand of Darkness", "Ursula K. Le Guin"},
	{2, "Dom Casmurro", "Machado de Assis"},
	{3, "The Remains of the Day", "Kazuo Ishiguro"},
}

type store interface {
	Books(ctx context.Context) ([]book, error)
}

type memory []book

func (m memory) Books(context.Context) ([]book, error) { return m, nil }

func routes(s store) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok\n"))
	})
	mux.HandleFunc("GET /version", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(version + "\n"))
	})
	mux.HandleFunc("GET /books", func(w http.ResponseWriter, r *http.Request) {
		books, err := s.Books(r.Context())
		if err != nil {
			log.Printf("books: %v", err)
			http.Error(w, "the catalogue is unavailable", http.StatusServiceUnavailable)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(books)
	})
	return mux
}

func main() {
	log.SetFlags(log.Ldate | log.Ltime | log.LUTC)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	var s store = memory(builtIn)
	if url := os.Getenv("DATABASE_URL"); url != "" {
		db, err := openPostgres(context.Background(), url)
		if err != nil {
			log.Fatalf("database: %v", err)
		}
		defer db.Close()
		s = db
		log.Printf("catalogue: postgres")
	} else {
		log.Printf("catalogue: built in, %d books", len(builtIn))
	}

	srv := &http.Server{Addr: ":" + port, Handler: routes(s)}
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		sig := <-stop
		log.Printf("received %v, shutting down", sig)
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		srv.Shutdown(ctx)
	}()

	log.Printf("shelf %s listening on :%s", version, port)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
	log.Printf("stopped")
}
