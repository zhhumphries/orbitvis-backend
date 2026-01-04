# Stage 1: Build
FROM golang:1.25.5-alpine AS builder
WORKDIR /app

# Copy shared module files first to leverage caching
COPY go.mod ./
COPY go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the catalog service
RUN go build -o /server ./cmd/catalog/main.go

# Stage 2: Create a minimal runtime image
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /server .
EXPOSE 8080
CMD ["./server"]