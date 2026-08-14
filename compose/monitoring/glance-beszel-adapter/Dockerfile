FROM golang:1.24-alpine AS build

WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/glance-beszel-adapter .

FROM scratch
COPY --from=build /out/glance-beszel-adapter /glance-beszel-adapter
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/glance-beszel-adapter"]
