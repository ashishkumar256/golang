package server

import (
	v1 "infra-golang-service/api/helloworld/v1"
	"infra-golang-service/internal/conf"
	"infra-golang-service/internal/service"

	hv1 "google.golang.org/grpc/health/grpc_health_v1"

	kgrpc "github.com/go-kratos/kratos/v2/transport/grpc"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/middleware/recovery"
	"github.com/go-kratos/kratos/v2/transport/http"
)

type HealthStatus struct {
	Status string `json:"status,omitempty"`
}

func healthCheckHandler(ctx http.Context) error {
	ctx.Result(200, HealthStatus{"healthy"})
	return nil
}

func healthCheckGrpcHandler(ctx http.Context) error {
	conn, err := kgrpc.DialInsecure(ctx,
		kgrpc.WithEndpoint("0.0.0.0:9000"),
	)
	if err != nil {

	}
	client := hv1.NewHealthClient(conn)
	reply, err := client.Check(ctx, &hv1.HealthCheckRequest{})
	if err != nil {
		ctx.Result(500, err.Error())
		return nil
	}
	ctx.Result(200, HealthStatus{reply.Status.String()})
	return nil
}

// NewHTTPServer new an HTTP server.
func NewHTTPServer(c *conf.Server, greeter *service.GreeterService, logger log.Logger) *http.Server {
	var opts = []http.ServerOption{
		http.Middleware(
			recovery.Recovery(),
		),
	}
	if c.Http.Network != "" {
		opts = append(opts, http.Network(c.Http.Network))
	}
	if c.Http.Addr != "" {
		opts = append(opts, http.Address(c.Http.Addr))
	}
	if c.Http.Timeout != nil {
		opts = append(opts, http.Timeout(c.Http.Timeout.AsDuration()))
	}
	srv := http.NewServer(opts...)
	srv.Route("/").GET("/health-check", healthCheckHandler)
	srv.Route("/").GET("/health-check-grpc", healthCheckGrpcHandler)
	v1.RegisterGreeterHTTPServer(srv, greeter)
	return srv
}
