#!/usr/bin/env bash

TARGET_URL="http://$(sudo kubectl get svc crust-service -n crust -o jsonpath='{.spec.clusterIP}')"

while true; do
    sudo kubectl get hpa -n webserver | tail -n 1 >> "replicas.log" 2>/dev/null
    sleep 1
done &
WATCHER_PID=$!

# Stable 10 request/sec
echo "--- Baseline: 10 req/s (1 minute) ---"
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="10/s" -duration="60s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta1.log"

# Ramp up 60 request/sec
echo "--- Spike: 60 req/s (3 minutes) ---"
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="60/s" -duration="180s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta2.log"

# Ramp down 10 request/sec
echo "--- Cool down: 10 req/s (1 minute) ---"
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="10/s" -duration="60s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta3.log"

echo "--- Traffic ramp finished. Monitoring HPA for an extra 5 minutes... ---"
sleep 5m

kill ${WATCHER_PID}

exit 0