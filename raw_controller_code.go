package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os/exec"
)

type RequestBody struct {
	Namespace string `json:"namespace"`
	Resource  string `json:"resource"`
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	// Parse JSON request body
	decoder := json.NewDecoder(r.Body)
	var requestBody RequestBody
	if err := decoder.Decode(&requestBody); err != nil {
		http.Error(w, "Failed to parse JSON request body", http.StatusBadRequest)
		return
	}

	// Construct command
	command := "kubectl"
	args := []string{"get", requestBody.Resource, "-n", requestBody.Namespace}

	// Execute command
	cmd := exec.Command(command, args...)

	// Capture command output
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Error executing command: %s", err)
		http.Error(w, "Failed to execute command", http.StatusInternalServerError)
		return
	}

	// Log command output
	log.Printf("Command output: %s", output)

	// Respond with success
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Command executed successfully"))
}

func main() {
	http.HandleFunc("/", handleRequest)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
