use axum::{
    http::StatusCode,
    body::Body,
    extract::Query,
    response::Response,
};
use serde::Deserialize;
use std::time::{Duration, Instant};

use crate::metrics::TOTAL_HTTP_REQUESTS;

#[derive(Deserialize)]
pub struct BurnQuery {
    burn: f64,
}

pub async fn get_burn(Query(params) : Query<BurnQuery>) -> Response {
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