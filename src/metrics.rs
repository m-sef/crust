use axum::{
    http::StatusCode,
    body::Body,
    response::Response,
};
use std::sync::Mutex;

pub static TOTAL_HTTP_REQUESTS : Mutex<u64> = Mutex::new(0);

pub async fn get_metrics() -> Response {
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