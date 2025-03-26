// ----------------------------------------------------------------------------
// File: 	register.go
// Brief: 	Command to register servers with controller.
// Project: Infrastructure Team - Project 1: Data Protection and Recovery
//
// Authors:
//     - Codey Funston: cfeng44@github.com
// 	   -
//
// Created: 07/03/2025
// Updated: 01/03/2025
//
// Note: Program skeleton created with cobra-cli.
// ----------------------------------------------------------------------------

package cmd

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strconv"

	"github.com/spf13/cobra"
)

var registerCmd = &cobra.Command{
	Use:   "register",
	Short: "Register an instance with a controller and assign its initial backup policy.",

	Run: func(cmd *cobra.Command, args []string) {
		// TODO:
		// Add error handling, especially to non-string flag objects to account
		// for parsing errors.
		hostname, _ := cmd.Flags().GetString("hostname")
		controller, _ := cmd.Flags().GetIP("controller")
		tool, _ := cmd.Flags().GetString("tool")
		copies, _ := cmd.Flags().GetCount("copies")
		freq, _ := cmd.Flags().GetString("freq")

		// Data for requests
		// -----------------
		addInstanceUrl := fmt.Sprintf("http://%s:8000/instance/", controller.String())
		addInstanceUrlWithParams := fmt.Sprintf("%s?hostname=%s", addInstanceUrl, url.QueryEscape(hostname))
		addPolicyURL := fmt.Sprintf("http://%s:8000/policy/", controller.String())

		// Request actions
		// ---------------
		res, err := http.Post(addInstanceUrlWithParams, "application/x-www-form-urlencoded", nil)
		if err != nil {
			log.Fatal(err)
		}
		body, err := io.ReadAll(res.Body)
		res.Body.Close()

		if res.StatusCode > 299 {
			log.Fatalf("Response failed with status code: %d and\nbody: %s\n", res.StatusCode, body)
		}
		fmt.Printf("%s", body)

		res, err = http.PostForm(addPolicyURL, url.Values{
			"hostname": {hostname},
			"tool":     {tool},
			"freq":     {freq},
			"copies":   {strconv.Itoa(copies)},
		})
		if err != nil {
			log.Fatal(err)
		}
		body, err = io.ReadAll(res.Body)
		res.Body.Close()

		if res.StatusCode > 299 {
			log.Fatalf("Response failed with status code: %d and\nbody: %s\n", res.StatusCode, body)
		}
		fmt.Printf("%s", body)
	},
}

func init() {
	instanceCmd.AddCommand(registerCmd)

	// Using methods other than just StringP() for later development when we
	// might want flags as proper objects.
	registerCmd.Flags().StringP("hostname", "H", "", "Hostname of the server instance.")
	registerCmd.Flags().IPP("controller", "C", nil, "IPV4 of the central server.")
	registerCmd.Flags().StringP("tool", "t", "", "Backup tool.")
	registerCmd.Flags().CountP("copies", "c", "Number of copies to hold.")
	registerCmd.Flags().StringP("freq", "f", "", "Cron interval for backups.")

	// We require every flag to be given.
	registerCmd.MarkFlagRequired("hostname")
	registerCmd.MarkFlagRequired("controller")
	registerCmd.MarkFlagRequired("tool")
	registerCmd.MarkFlagRequired("copies")
	registerCmd.MarkFlagRequired("freq")
}
