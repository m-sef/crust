# crust

Simple REST API written in Rust for benchmarking.

## Setup

```bash
# Building crust locally
cargo build --release

# Running crust locally
./target/release/crust --help

# Building crust docker image
sudo docker build -t crust .

# Running crust docker container
sudo docker run -d -p 8080:8080 crust:latest

# Deploying crust on Kubernetes
sudo kubectl apply -f yaml/crust.yaml
```

## Usage

```
Benchmarking REST API. It is called crust because it burns!

Usage: crust [OPTIONS]

Options:
  -i, --ip-address <IP_ADDRESS>        IP Address to bind to [default: 0.0.0.0]
  -p, --port <PORT>                    Port to bind to [default: 8080]
  -t, --threads <THREADS>              Number of threads to run with [default: 1]
  -s, --startup-delay <STARTUP_DELAY>  Time in ms to delay startup
  -h, --help                           Print help
  -V, --version                        Print version
```

## REST API

### `GET /healthy`

Liveness/readiness check. Always returns `200 OK` with body `OK`.

### `GET /metrics`

Prometheus-formatted metrics. Currently exposes a single counter, `http_requests_total`, incremented on each `/burn` request.

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total 42
```

### `GET /burn?burn=<milliseconds>`

Busy-loops the handler thread for `burn` milliseconds (floating point) to generate CPU load for benchmarking, then returns `200 OK` with body `OK`.

| Query param | Type  | Required | Description                        |
|-------------|-------|----------|-------------------------------------|
| `burn`      | f64   | yes      | Duration to burn CPU, in milliseconds |

## Example:

```bash
# Burn for 100ms
curl "http://localhost:8080/burn?burn=100"
```