// ----------------------------------------------------------------------------
// File: 	instance.go
// Brief: 	Command to perform actions related to server instances.
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
	"github.com/spf13/cobra"
)

var instanceCmd = &cobra.Command{
	Use:   "instance",
	Short: "Perform actions on specific instances.",
}

func init() {
	rootCmd.AddCommand(instanceCmd)
}
