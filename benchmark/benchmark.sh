#!/usr/bin/env bash

TARGET_URL="http://$(kubectl get svc crust-service -n crust -o jsonpath='{.spec.clusterIP}')"

# Stable 10 request/sec
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="10/s" -duration="60s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta1.log"

# Ramp up 60 request/sec
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="60/s" -duration="180s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta2.log"

# Ramp down 10 request/sec
echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="10/s" -duration="60s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta3.log"

exit 0