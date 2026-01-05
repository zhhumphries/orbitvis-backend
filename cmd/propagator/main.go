package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"google.golang.org/api/idtoken"
)

func main() {
	log.Println("Starting Propagator Service...")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", handler)

	log.Printf("Propagator Service listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Error starting Propagator Service: %v", err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	// Get CATALOG_URL from environment variable set by Terraform
	catalogURL := os.Getenv("CATALOG_URL")
	if catalogURL == "" {
		log.Printf("CATALOG_URL environment variable is not set")
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Make the authenticated call to the catalog service
	ctx := context.Background()
	client, err := idtoken.NewClient(ctx, catalogURL)
	if err != nil {
		log.Printf("Failed to create ID token client: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Make the call to the catalog service
	resp, err := client.Get(catalogURL)
	if err != nil {
		log.Printf("Failed to call catalog service: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// read the response body from catalog service
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Failed to read response body: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Propagator Service Report: Upstream Catalog Service says: %s", string(body))
}