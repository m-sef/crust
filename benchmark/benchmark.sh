#!/usr/bin/env bash

TARGET_URL="http://$(kubectl get svc webserver-service -n webserver -o jsonpath='{.spec.clusterIP}')"

echo "GET ${TARGET_URL}:8080/burn?burn=20"| \
    vegeta attack -rate="10/s" -duration="60s" -keepalive=false | \
    vegeta encode -to=csv -output="vegeta.log"

exit 0