FROM golang:1.20.1-alpine3.17
RUN GRPC_HEALTH_PROBE_VERSION=v0.3.6 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe


RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
RUN go install github.com/go-kratos/kratos/cmd/kratos/v2@latest


RUN go install github.com/go-kratos/kratos/cmd/kratos/v2@latest

COPY . /app/golang

WORKDIR /app/golang

#COPY infra-golang-service.zip /app

EXPOSE 8000
EXPOSE 9000

ENTRYPOINT ["kratos", "run"]
