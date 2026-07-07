#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

run_benchmark() {
    NAME=$1
    YAML=$2
    RUNS=$3

    for run_id in $(seq 1 ${RUNS}); do
        FOLDER_NAME="$SCRIPT_DIR/results/${NAME}/experiment_run_${run_id}"
        mkdir -p "${FOLDER_NAME}"

        sudo kubectl apply -f $YAML
        sudo kubectl wait --for=condition=Ready pod --all -n crust --timeout=60s

        TARGET_URL="http://$(sudo kubectl get svc crust-service -n crust -o jsonpath='{.spec.clusterIP}')"

        while true; do
            sudo kubectl get hpa -n crust | tail -n 1 >> "${FOLDER_NAME}/replicas.log" 2>/dev/null
            sleep 1
        done &
        WATCHER_PID=$!

        # Stable 50 request/sec
        echo "--- Baseline: 50 req/s (5 minute) ---"
        echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
            vegeta attack -rate="50/s" -duration="300s" -keepalive=false | \
            vegeta encode -to=csv -output="${FOLDER_NAME}/vegeta1.log"
        
        ## Ramp up 120 request/sec
        #echo "--- Spike: 120 req/s (3 minutes) ---"
        #echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
        #    vegeta attack -rate="120/s" -duration="180s" -keepalive=false | \
        #    vegeta encode -to=csv -output="${FOLDER_NAME}/vegeta2.log"

        ## Ramp down 50 request/sec
        #echo "--- Cool down: 50 req/s (1 minute) ---"
        #echo "GET ${TARGET_URL}:8080/burn?burn=50"| \
        #    vegeta attack -rate="50/s" -duration="60s" -keepalive=false | \
        #    vegeta encode -to=csv -output="${FOLDER_NAME}/vegeta3.log"

        #echo "--- Traffic ramp finished. Monitoring HPA for an extra 5 minutes... ---"
        #sleep 5m

        kill ${WATCHER_PID}

        sudo kubectl delete -f $YAML
        sudo kubectl wait --for=delete pod --all -n crust --timeout=60s
    done
}

run_benchmark default_hpa_experimental2 $SCRIPT_DIR/../yaml/crust.yaml 1

exit 0
