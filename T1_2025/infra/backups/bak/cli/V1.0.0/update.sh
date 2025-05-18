#!/bin/bash

source ./utils.sh

update() {
    id=""
    name=""
    image=""
    copies=""
    frequency=""

    while [[ $# -gt 0 ]]; do
        case "$1" in 
            -I|--id)
                if [[ -n "$2" ]]; then
                    id="$2"
                    shift # shifts away the flag value
                else
                    err "Flag -i|--id requires a value."
                fi
                ;;

            -n|--name)
                if [[ -n "$2" ]]; then
                    name="$2"
                    shift
                else
                    err "Flag -n|--name requires a value."
                fi
                ;;

            -i|--image)
                if [[ -n "$2" ]]; then
                    image="$2"
                    shift
                else
                    err "Flag -i|--image requires a value."
                fi
                ;;

            -c|--copies)
                if [[ -n "$2" ]]; then
                    copies="$2"
                    shift
                else
                    err "Flag -c|--copies requires a value."
                fi
                ;;

            -f|--frequency)
                if [[ -n "$2" ]]; then
                    frequency="$2"
                    shift
                else
                    err "Flag -f|--frequency requires a value."
                fi
                ;;

            -*)
                err "Unkown flag: $1"
                ;;
        esac
        shift # shifts away the flag
    done

    if [[ -z "$id" || -z "$name" || -z "$image" || -z "$copies" || -z "$frequency" ]]; then
        err "All flags (I|--id, -n|--name, i|--image, -c|--copies, -f|--frequency) are required."
    fi

    res=`curl --silent -X POST http://localhost:1234/api/update/container \
        -d "{
            \"container-id\": \"$id\",
            \"container-name\": \"$name\",
            \"image\": \"$image\",
            \"copies\": \"$copies\",
            \"frequency\": \"$frequency\"
        }"`

    statusCode=$(echo $res | jq -r ".status")
    if [[ $statusCode == "ok" ]]; then
        echo "Successfully registered container: $name"
    else
        err "Error in request."
    fi
}
