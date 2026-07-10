use axum::{
    http::StatusCode,
    body::Body,
    response::Response,
};

pub async fn get_healthy_handler() -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "text/plain")
        .body(Body::from("OK"))
        .unwrap()
}