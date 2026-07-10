mod metrics;
mod healthy;
mod burn;

use axum::{
    routing::get,
    Router,
};
use clap::Parser;
use log::{info};

use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::{thread, time::Duration};

use crate::metrics::get_metrics_handler;
use crate::healthy::get_healthy_handler;
use crate::burn::get_burn_handler;

/// Benchmarking REST API. It is called crust because it burns!
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// IP Address to bind to
    #[arg(short, long, default_value_t = IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)))]
    ip_address: IpAddr,

    /// Port to bind to
    #[arg(short, long, default_value_t = 8080)]
    port: u16,

    /// Number of threads to run with
    #[arg(short, long, default_value_t = 1)]
    threads: usize,

    /// Time in ms to delay startup
    #[arg(short, long)]
    startup_delay: Option<u64>,
}

fn main() {
    env_logger::init();

    let args = Args::parse();

    match &args.startup_delay {
        Some(startup_delay_ms) => {
            info!("Startup Delay: {}ms", *startup_delay_ms);
            thread::sleep(Duration::from_millis(*startup_delay_ms));
        }
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

            let socket = SocketAddr::new(args.ip_address, args.port);
            let listener = tokio::net::TcpListener::bind(socket).await.unwrap();
            info!("Listening on {}", socket);
            axum::serve(listener, app).await.unwrap();
        })
}