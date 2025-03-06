#!/bin/bash

if ! command -v python3 &> /dev/null
then
    echo "Python3 not found. Installing..."
    apt update && apt install -y python3 python3-pip
fi

echo "Installing dependencies..."
pip3 install requests

mv ./bak /usr/local/bin
chmod +x /usr/local/bin/bak

source ~/.bashrc