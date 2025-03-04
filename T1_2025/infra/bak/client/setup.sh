#!/bin/bash

CONTROLLER="0.0.0.0"
PORT="8000"

# policy=$(curl -s "http://$CONTROLLER:$PORT/instance/$(hostname)/policy/")
policy=$(curl -s "http://$CONTROLLER:$PORT/instance/codey-mac.local/policy/")

tool=$(echo "$policy" | jq -r '.tool')
freq=$(echo "$policy" | jq -r '.freq')
copies=$(echo "$policy" | jq -r '.copies')

echo $policy
echo $tool
echo $freq
echo $copies

case "$policy" in
    "HARD")
        echo "HARD"
        ;;
    "SOFT")
        echo "SOFT"
        ;;
    "NORMAL")
        echo "NORMAL"
        ;;
esac

echo "Response from controller: $response"
