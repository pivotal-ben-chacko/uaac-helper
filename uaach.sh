#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--api)
    CF_API="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--username)
    CF_USER="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--lib)
    CF_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


if [ -z "$CF_CARNIVORE_API" ]; then
    echo "Please set CF_CARNIVORE_API before running this tool"; exit 1;
fi

uaac target "$CF_CARNIVORE_API/uaa" --skip-ssl-validation
uaac token owner get opsman admin -s ""

export ACCESS_TOKEN=$(uaac context | grep access_token | awk '{print $2}')
curl -k "https://${CF_CARNIVORE_API}/api/v0/deployed/products" -H "Authorization: Bearer $ACCESS_TOKEN" > output.json
deployments=($(jq -r '.[].installation_name'  output.json))

echo "--- Deployments ---"
for i in "${!deployments[@]}"; do 
	printf "%s) %s\n" "$i" "${deployments[$i]}"
done
echo "-------------------"

read -p "Select Deployment: " dIndex
echo "Deployment: ${deployments[$index]}"
curl -k "https://${CF_CARNIVORE_API}/api/v0/deployed/products/${deployments[$dIndex]}/credentials" -H "Authorization: Bearer $ACCESS_TOKEN" > output.json

credentials=($(jq -r '.credentials[]'  output.json))
for i in "${!credentials[@]}"; do
        printf "%s) %s\n" "$i" "${credentials[$i]}"
done
read -p "Select Credentials: " cIndex
curl -k "https://${CF_CARNIVORE_API}/api/v0/deployed/products/${deployments[$dindex]}/credentials/${credentials[$cIndex]}" -H "Authorization: Bearer $ACCESS_TOKEN" > output.json
jq . output.json

if [ -z "$UAA_PAS_API" ]; then
    echo "Please set UAA_PAS_API before running this tool!"; exit 1;
fi

ident=($(jq -r .credential.value.identity ./output.json))
pass=($(jq -r .credential.value.password ./output.json))

uaac target "$UAA_PAS_API" --skip-ssl-validation
uaac token client get "$ident" -s "$pass"

echo "-- Access Token --"
echo $(uaac context | grep access_token | awk '{print $2}')i
