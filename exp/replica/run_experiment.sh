#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BURN=20
RPS_LIST=(10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200)

run_rate() {
    local RATE=$1
    local DURATION=$2
    local LOG_FILE=$3

    TARGET_URL="http://$(sudo kubectl get svc crust-service -n crust -o jsonpath='{.spec.clusterIP}')"

    echo "GET ${TARGET_URL}:8080/burn?burn=${BURN}" | \
        vegeta attack -rate="${RATE}/s" -duration="${DURATION}" -keepalive=false | \
        vegeta encode -to=csv -output="${LOG_FILE}"
}

run_experiment() {
    NAME=$1
    YAML=$2
    RUNS=$3

    sudo kubectl apply -f "${YAML}"
    sleep 5
    sudo kubectl wait --for=condition=Ready pod --all -n crust --timeout=60s

    for (( i = 1; i <= RUNS; i++ )); do
        sudo kubectl scale deployment "${NAME}" -n crust --replicas="${i}"
        sudo kubectl wait --for=condition=Ready pod --all -n crust --timeout=60s

        for rps in "${RPS_LIST[@]}"; do
            echo "--- Replicas: ${i}, RPS: ${RPS} ---"
            run_rate "${rps}" "10s" "${SCRIPT_DIR}/results/${i}_${rps}.log"
        done
    done

    sudo kubectl delete -f "${YAML}"
    sudo kubectl wait --for=delete pod --all -n crust --timeout=60s
}

run_experiment crust-deployment "${SCRIPT_DIR}/../../yaml/crust.yaml" 20

exit 0