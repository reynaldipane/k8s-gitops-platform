# Build stage: full Go toolchain, thrown away after the build
FROM golang:1.27.2-alpine AS build
WORKDIR /src

# Dependencies first, so this layer is cached until go.mod changes
COPY go.mod ./
RUN go mod download

COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath \
    -ldflags "-s -w -X main.version=${VERSION}" -o /out/app .

# Runtime stage: no shell, no package manager, runs as non-root
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
