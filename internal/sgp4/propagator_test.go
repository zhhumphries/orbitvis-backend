package sgp4

import (
	"context"
	"testing"
	"time"
)

func TestPropagateISS(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	nowUTC := time.Now().UTC()
	t.Logf("nowUTC: %v", nowUTC)
	lat, lon, altKm, err := PropagateISS(ctx, nowUTC)
	if err != nil {
		t.Fatalf("PropagateISSNow error: %v", err)
	}

	// Basic sanity checks
	if lat < -90 || lat > 90 {
		t.Fatalf("latitude out of range: %f", lat)
	}
	if lon < -180 || lon > 180 {
		t.Fatalf("longitude out of range: %f", lon)
	}
	// ISS typical altitude ~400 km; allow a broad window to reduce flakiness.
	if altKm < 300 || altKm > 500 {
		t.Fatalf("altitude unexpected: %f km", altKm)
	}

	t.Logf("ISS @ now (local): lat=%.4f°, lon=%.4f°, alt=%.1f km", lat, lon, altKm)
}


