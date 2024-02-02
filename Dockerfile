FROM golang:1.20.1-alpine3.17 AS grpc-health-probe-builder
RUN GRPC_HEALTH_PROBE_VERSION=v0.3.6 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

FROM golang:1.20.1-alpine3.17 AS grpcurl-builder
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

FROM golang:1.18 AS builder

COPY . /src
WORKDIR /src

RUN GOPROXY=https://goproxy.cn make build

FROM debian:stable-slim

COPY --from=grpc-health-probe-builder /bin/grpc_health_probe /usr/local/bin/

COPY --from=grpcurl-builder /go/bin/grpcurl /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates  \
        netbase \
        && rm -rf /var/lib/apt/lists/ \
        && apt-get autoremove -y && apt-get autoclean -y

COPY --from=builder /src/bin /app

WORKDIR /app

EXPOSE 8000
EXPOSE 9000
VOLUME /data/conf

CMD ["./server", "-conf", "/data/conf"]
