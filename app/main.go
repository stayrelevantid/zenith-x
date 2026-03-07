// Version 1.0.2 - External Secrets Test
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type Response struct {
	Status    string    `json:"status"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
	Hostname  string    `json:"hostname"`
}

var version = getEnv("APP_VERSION", "1.0.2")

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	writeJSON(w, http.StatusOK, Response{
		Status:    "ok",
		Message:   "Welcome to Zenith-X 🚀",
		Timestamp: time.Now().UTC(),
		Version:   version,
		Hostname:  hostname,
	})
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "healthy",
	})
}

func handleSecret(w http.ResponseWriter, r *http.Request) {
	secretValue := getEnv("APP_SECRET", "not-set")
	writeJSON(w, http.StatusOK, map[string]string{
		"secret_status": "present",
		"secret_value":  secretValue,
	})
}

func main() {
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	r.Get("/", handleRoot)
	r.Get("/health", handleHealth)
	r.Get("/secret", handleSecret)

	port := getEnv("PORT", "8080")
	log.Printf("🚀 Zenith-X server starting on port %s (version %s)", port, version)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
