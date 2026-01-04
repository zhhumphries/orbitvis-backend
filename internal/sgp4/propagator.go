package sgp4

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	satellite "github.com/joshuaferrara/go-satellite"
)

const (
	// Celestrak endpoint for ISS (ZARYA) TLEs in classic 2-line format
	celestrakISSTLEURL = "https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=tle"
)

// FetchISSTLE retrieves the latest ISS TLE from Celestrak.
// It returns the two TLE lines (line1 and line2).
func FetchISSTLE(ctx context.Context) (string, string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, celestrakISSTLEURL, nil)
	if err != nil {
		return "", "", fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Accept", "text/plain")

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", "", fmt.Errorf("request celestrak: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return "", "", fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(body))
	}

	line1, line2, err := parseTLE(resp.Body)
	if err != nil {
		return "", "", err
	}
	return line1, line2, nil
}

// parseTLE scans a text stream and extracts the first pair of TLE lines
// beginning with '1 ' and '2 ' respectively.
func parseTLE(r io.Reader) (string, string, error) {
	sc := bufio.NewScanner(r)
	var l1, l2 string
	for sc.Scan() {
		s := strings.TrimSpace(sc.Text())
		if len(s) == 0 {
			continue
		}
		if strings.HasPrefix(s, "1 ") {
			l1 = s
			// Expect the next relevant line starting with '2 '
			for sc.Scan() {
				next := strings.TrimSpace(sc.Text())
				if strings.HasPrefix(next, "2 ") {
					l2 = next
					break
				}
			}
			break
		}
	}
	if err := sc.Err(); err != nil {
		return "", "", fmt.Errorf("scan TLE: %w", err)
	}
	if l1 == "" || l2 == "" {
		return "", "", errors.New("unable to find ISS TLE lines")
	}
	return l1, l2, nil
}

// PropagateISS fetches the current ISS TLE and propagates to the caller's local time.
// It returns latitude (deg), longitude (deg), and altitude (km).
func PropagateISS(ctx context.Context, time time.Time) (float64, float64, float64, error) {
	line1, line2, err := FetchISSTLE(ctx)
	if err != nil {
		return 0, 0, 0, err
	}

	// Initialize satellite with WGS-84 gravitational constants.
	sat := satellite.TLEToSat(line1, line2, satellite.GravityWGS84)

	year, month, day := time.Date()
	hour, min, sec := time.Clock()

	pos, _ := satellite.Propagate(
		sat,
		year,
		int(month),
		day,
		hour,
		min,
		sec,
	)

	gmst := satellite.GSTimeFromDate(year, int(month), day, hour, min, sec)
	altKm, _, llRad := satellite.ECIToLLA(pos, gmst)
	llDeg := satellite.LatLongDeg(llRad)
	return llDeg.Latitude, llDeg.Longitude, altKm, nil
}


