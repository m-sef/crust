#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BURN=20
RPS_LIST=(25 50 75 100 125 150 175 200 225 250 275 300 325 350 375 400 425 450 475 500)
WORKER=10.10.1.1
WORKER_IF=enp6s0f0
SSH_OPTS="-o StrictHostKeyChecking=no"

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
            echo "--- Replicas: ${i}, RPS: ${rps} ---"

            FOLDER_NAME="${SCRIPT_DIR}/results/${i}_${rps}"
            mkdir -p $FOLDER_NAME

            # Start eBPF Probe on worker node (output stays on the worker, not piped back over the NIC under test)
            ssh $SSH_OPTS $WORKER "sudo /local/ebpf-probe/build/ebpf_probe -i ${WORKER_IF} > /tmp/ebpf_probe.log 2>&1" &
            EBPF_PROBE_PID=$!

            # Wait until the probe has actually attached before generating load
            until ssh $SSH_OPTS $WORKER "sudo test -e /sys/fs/bpf/ebpf_probe/cpu0/${WORKER_IF}"; do
                sleep 0.2
            done

            run_rate "${rps}" "10s" "${FOLDER_NAME}/vegeta.log"

            ssh $SSH_OPTS $WORKER "sudo bash -c 'cat /sys/fs/bpf/ebpf_probe/cpu*/summary'"      > "${FOLDER_NAME}/summary.log"
            ssh $SSH_OPTS $WORKER "sudo bash -c 'cat /sys/fs/bpf/ebpf_probe/cpu*/${WORKER_IF}'" > "${FOLDER_NAME}/${WORKER_IF}.log"

            # Kill eBPF Probe on worker node to reset stats
            ssh $SSH_OPTS $WORKER "sudo pkill -f ebpf_probe"

            kill ${EBPF_PROBE_PID}
        done
    done

    sudo kubectl delete -f "${YAML}"
    sudo kubectl wait --for=delete pod --all -n crust --timeout=60s
}

run_experiment crust-deployment "${SCRIPT_DIR}/../../yaml/crust.yaml" 20

exit 0