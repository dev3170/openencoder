FROM golang:1.12-alpine AS builder

# Create the user and group files that will be used in the running container to
# run the process as an unprivileged user.
RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

# Outside GOPATH since we're using modules.
WORKDIR /src

# Required for fetching dependencies.
RUN apk add --no-cache ca-certificates git

# Fetch dependencies to cache.
COPY go.mod go.sum ./
RUN go mod download

# Copy project source files.
COPY . .

# Build.
RUN CGO_ENABLED=0 GOOS=linux go build -installsuffix 'static' -v -o /app .

# Final release image.
FROM alpine:3.5

# Import the user and group files from the first stage.
COPY --from=builder /user/group /user/passwd /etc/

# Import the Certificate-Authority certificates for enabling HTTPS.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Import the project executable.
COPY --from=builder /app /app

EXPOSE 8080

# Perform any further action as an unpriviledged user.
USER nobody:nobody

# Run binary.
ENTRYPOINT ["/app"]
