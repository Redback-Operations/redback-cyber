// ----------------------------------------------------------------------------
// File: 	root.go
// Brief: 	Root command for bak CLI.
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
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use: "bak",
	Long: ` 
██████╗  █████╗ ██╗  ██╗
██╔══██╗██╔══██╗██║ ██╔╝
██████╔╝███████║█████╔╝   -- Backup and Recovery Management
██╔══██╗██╔══██║██╔═██╗ 
██████╔╝██║  ██║██║  ██╗
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
               `,
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {}
