package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	log.Print("SaaS Platform App request received")
	fmt.Fprintf(w, "Hello from the SaaS Platform App!\n")
}

func main() {
	log.Print("SaaS Platform App server starting on port 8080...")

	http.HandleFunc("/", handler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}
