FROM rust:1-alpine AS crust-build
WORKDIR /crust
COPY . .
RUN cargo build --release

FROM alpine
COPY --from=crust-build /crust/target/release/crust /usr/bin
EXPOSE 8080
CMD [ "crust" ]