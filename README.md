# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## Docker image notes

- `bash`: the script uses a Bash shebang (`#!/usr/bin/env bash`).
- `cowsay`: renders the quote as ASCII art.
- `fortune-mod`: provides the `fortune` command for random quotes.
- `netcat-openbsd`: provides `nc`, used to listen for HTTP requests.
- `ca-certificates`: standard TLS trust store; good default even if not strictly required.

## Kubernetes notes

- Deployment: tells Kubernetes to run the Wisecow container and keep it running.
- Service: creates a stable address in the cluster and forwards port 80 to app port 4499.
- Readiness probe: a small check (TCP to port 4499) so Kubernetes only sends traffic when the app is ready.

## How to use?

1. Run `./wisecow.sh`
2. Point the browser to server port (default 4499)

## What to expect?
![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)

# Problem Statement
Deploy the wisecow application as a k8s app

## Requirement
1. Create Dockerfile for the image and corresponding k8s manifest to deploy in k8s env. The wisecow service should be exposed as k8s service.
2. Github action for creating new image when changes are made to this repo
3. [Challenge goal]: Enable secure TLS communication for the wisecow app.

## Expected Artifacts
1. Github repo containing the app with corresponding dockerfile, k8s manifest, any other artifacts needed.
2. Github repo with corresponding github action.
3. Github repo should be kept private and the access should be enabled for following github IDs: nyrahul
