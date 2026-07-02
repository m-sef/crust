use axum::{
    routing::get,
    http::StatusCode,
    body::Body,
    extract::Query,
    response::Response,
    Router,
};
use serde::Deserialize;
use std::sync::Mutex;
use std::time::{Duration, Instant};
use clap::Parser;

/// Benchmarking REST API. It is called crust because it burns!
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Number of threads to run with
    #[arg(short, long, default_value_t = 1)]
    threads: u8,
}

static TOTAL_HTTP_REQUESTS : Mutex<u64> = Mutex::new(0);

#[tokio::main]
async fn main() {
    let args = Args::parse();

    let app = Router::new()
        .route("/metrics", get(metrics))
        .route("/burn", get(burn));
    
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn metrics() -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "text/plain")
        .body(Body::from(format!(
            "# HELP http_requests_total Total number of HTTP requests\n\
             # TYPE http_requests_total counter\n\
             http_requests_total {}\n",
            *TOTAL_HTTP_REQUESTS.lock().unwrap()
        )))
        .unwrap()
}

#[derive(Deserialize)]
struct BurnQuery {
    burn: f64,
}

async fn burn(Query(params) : Query<BurnQuery>) -> Response {
    *TOTAL_HTTP_REQUESTS.lock().unwrap() += 1;

    let time_ms = params.burn;
    let time_end = Instant::now() + Duration::from_secs_f64(time_ms / 1000.0);

    let mut x = 0.0_f64;
    while Instant::now() <= time_end {
        x += (x + 1.0).sqrt();
    }

    println!("burn={}, {}", time_ms, x);

    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "text/plain")
        .body(Body::from("OK\n"))
        .unwrap()
}