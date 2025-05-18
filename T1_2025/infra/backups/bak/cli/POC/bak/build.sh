#!/bin/bash

GOOS=windows GOARCH=amd64 go build -o ./builds/bak.exe

GOOS=linux GOARCH=amd64 go build -o ./builds/bak

GOOS=darwin GOARCH=amd64 go build -o ./builds/bak-macos

chmod +x ./builds/bak-macos