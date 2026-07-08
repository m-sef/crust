mod metrics;
mod healthy;
mod burn;

use axum::{
    routing::get,
    Router,
};
use clap::Parser;

use crate::metrics::get_metrics;
use crate::healthy::get_healthy;
use crate::burn::get_burn;

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
}

fn main() {
    let args = Args::parse();

    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(args.threads)
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let app = Router::new()
                .route("/metrics", get(get_metrics))
                .route("/healthy", get(get_healthy))
                .route("/burn", get(get_burn));

            let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", args.port)).await.unwrap();
            axum::serve(listener, app).await.unwrap();
        })
}