package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"sync/atomic"
	"time"
)

type app struct {
	version  string
	hostname string
	ready    atomic.Bool
}

func newApp(version, hostname string) *app {
	a := &app{version: version, hostname: hostname}
	a.ready.Store(true)
	return a
}

func (a *app) setReady(ready bool) {
	a.ready.Store(ready)
}

func (a *app) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", a.handleRoot)
	mux.HandleFunc("GET /healthz", a.handleHealthz)
	mux.HandleFunc("GET /readyz", a.handleReadyz)
	return logRequests(mux)
}

type rootResponse struct {
	Message  string `json:"message"`
	Version  string `json:"version"`
	Hostname string `json:"hostname"`
}

func (a *app) handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(rootResponse{
		Message:  "hello from k8s-gitops",
		Version:  a.version,
		Hostname: a.hostname,
	})
}

// handleHealthz is the liveness probe: it only proves the process can serve HTTP.
// Don't add dependency checks here, or an outage restarts every pod.
func (a *app) handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok\n"))
}

// handleReadyz is the readiness probe: it fails during shutdown so the pod
// is taken out of the Service before the server stops.
func (a *app) handleReadyz(w http.ResponseWriter, r *http.Request) {
	if !a.ready.Load() {
		http.Error(w, "shutting down", http.StatusServiceUnavailable)
		return
	}
	w.Write([]byte("ready\n"))
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

// logRequests logs every request except the probes, which would flood the logs.
func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/healthz" || r.URL.Path == "/readyz" {
			next.ServeHTTP(w, r)
			return
		}
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		slog.Info("request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", rec.status,
			"duration_ms", time.Since(start).Milliseconds(),
		)
	})
}
