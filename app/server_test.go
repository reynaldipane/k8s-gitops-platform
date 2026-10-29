package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRoot(t *testing.T) {
	a := newApp("abc123", "pod-1")
	rec := httptest.NewRecorder()
	a.routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	var got rootResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if got.Version != "abc123" || got.Hostname != "pod-1" {
		t.Errorf("got %+v, want version abc123 and hostname pod-1", got)
	}
}

func TestProbes(t *testing.T) {
	a := newApp("dev", "pod-1")
	h := a.routes()

	tests := []struct {
		name  string
		path  string
		ready bool
		want  int
	}{
		{"liveness", "/healthz", true, http.StatusOK},
		{"liveness during shutdown", "/healthz", false, http.StatusOK},
		{"readiness", "/readyz", true, http.StatusOK},
		{"readiness during shutdown", "/readyz", false, http.StatusServiceUnavailable},
		{"unknown path", "/nope", true, http.StatusNotFound},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			a.setReady(tt.ready)
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, tt.path, nil))
			if rec.Code != tt.want {
				t.Errorf("GET %s = %d, want %d", tt.path, rec.Code, tt.want)
			}
		})
	}
}
