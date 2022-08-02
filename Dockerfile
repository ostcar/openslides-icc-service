FROM golang:1.19.0-alpine as base
WORKDIR /root/

RUN apk add git

COPY go.mod go.sum ./
RUN go mod download

COPY cmd cmd
COPY internal internal

# Build service in seperate stage.
FROM base as builder
RUN CGO_ENABLED=0 go build ./cmd/icc
RUN CGO_ENABLED=0 go build ./cmd/healthcheck


# Development build.
FROM base as development

RUN ["go", "install", "github.com/githubnemo/CompileDaemon@latest"]
EXPOSE 9012
ENV AUTH ticket

CMD CompileDaemon -log-prefix=false -build="go build ./cmd/icc" -command="./icc"


# Productive build
FROM scratch

LABEL org.opencontainers.image.title="OpenSlides ICC Service"
LABEL org.opencontainers.image.description="With the OpenSlides ICC Service clients can communicate with each other."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/OpenSlides/openslides-icc-service"

COPY --from=builder /root/icc .
COPY --from=builder /root/healthcheck .
EXPOSE 9007
ENV AUTH ticket
ENTRYPOINT ["/icc"]
HEALTHCHECK CMD ["/healthcheck"]
