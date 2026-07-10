mod metrics;
mod healthy;
mod burn;

use axum::{
    routing::get,
    Router,
};
use clap::Parser;
use std::{thread, time::Duration};

use crate::metrics::get_metrics_handler;
use crate::healthy::get_healthy_handler;
use crate::burn::get_burn_handler;

/// Benchmarking REST API. It is called crust because it burns!
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Port to run on
    #[arg(short, long, default_value_t = 8080)]
    port: u16,

    /// Number of threads to run with
    #[arg(short, long, default_value_t = 1)]
    threads: usize,

    /// Time in ms to delay startup
    #[arg(long)]
    startup_delay: Option<u64>,
}

fn main() {
    let args = Args::parse();

    match &args.startup_delay {
        Some(startup_delay_ms) => thread::sleep(Duration::from_millis(*startup_delay_ms)),
        None => (),
    }

    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(args.threads)
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let app = Router::new()
                .route("/metrics", get(get_metrics_handler))
                .route("/healthy", get(get_healthy_handler))
                .route("/burn", get(get_burn_handler));

            let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", args.port)).await.unwrap();
            axum::serve(listener, app).await.unwrap();
        })
}