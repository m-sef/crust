use axum::{
    http::{header::HOST, HeaderMap, Method, StatusCode, Uri},
    body::Body,
    extract::{ConnectInfo, Query},
    response::Response,
};
use serde::Deserialize;
use log::{info};
use std::net::SocketAddr;
use std::time::{Duration, Instant};

use crate::metrics::TOTAL_HTTP_REQUESTS;

#[derive(Deserialize)]
pub struct BurnQuery {
    burn: u64,
}

pub async fn get_burn_handler(
    ConnectInfo(addr): ConnectInfo<SocketAddr>, method: Method, uri: Uri,
    headers: HeaderMap, Query(params): Query<BurnQuery>) -> Response
{
    let host = headers
        .get(HOST)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("unknown");

    let time_ms = params.burn;
    let time_end = Instant::now() + Duration::from_millis(time_ms);

    // This is probably a pointless optimization; moved code accessing mutex lock inside "burn logic"
    *TOTAL_HTTP_REQUESTS.lock().unwrap() += 1;

    let mut x = 0.0_f64;
    while Instant::now() <= time_end {
        x += (x + 1.0).sqrt();
    }

    info!("{} {} http://{}{}", addr, method, host, uri);

    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "text/plain")
        .body(Body::from("OK\n"))
        .unwrap()
}