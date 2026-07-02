# crust

Simple REST API written in Rust for benchmarking.

## Setup

```bash
# Building crust
cargo build --release

# Running crust
./target/release/crust --help
```

## Usage

```bash
Benchmarking REST API. It is called crust because it burns!

Usage: crust [OPTIONS]

Options:
  -p, --port <PORT>        Port to run on [default: 8080]
  -t, --threads <THREADS>  Number of threads to run with [default: 1]
  -h, --help               Print help
  -V, --version            Print version
```