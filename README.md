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
- Ingress: exposes the service outside the cluster and is used by cert-manager to issue TLS certs.

## TLS with cert-manager (real-world setup)

1. Install cert-manager and an Ingress controller (e.g., nginx) in your cluster.
2. Edit `k8s/cluster-issuer.yaml` and set `CHANGE_ME_EMAIL`.
3. Edit `k8s/ingress.yaml` and set `CHANGE_ME_DOMAIN` to your real DNS name.
4. Apply manifests:
   - `kubectl apply -f k8s/cluster-issuer.yaml`
   - `kubectl apply -f k8s/deployment.yaml`
   - `kubectl apply -f k8s/service.yaml`
   - `kubectl apply -f k8s/ingress.yaml`
5. cert-manager will create the `wisecow-tls` secret automatically after ACME validation.

## Local TLS demo (self-signed)

This is a local-only HTTPS demo for minikube when you don't have a public domain.

1. Update `k8s/ingress.yaml` to use `wisecow.local` (already set).
2. Create a self-signed cert and TLS secret:
   - `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout wisecow.key -out wisecow.crt -subj "/CN=wisecow.local" -addext "subjectAltName=DNS:wisecow.local"`
   - `kubectl create secret tls wisecow-tls --cert=wisecow.crt --key=wisecow.key`
3. Apply manifests:
   - `kubectl apply -f k8s/deployment.yaml`
   - `kubectl apply -f k8s/service.yaml`
   - `kubectl apply -f k8s/ingress.yaml`
4. Get minikube IP: `minikube ip`
5. Access HTTPS locally:
   - Add to `/etc/hosts`: `<minikube-ip> wisecow.local`
   - Then open `https://wisecow.local` (browser will warn because self-signed).
   - Or use curl: `curl -k --resolve wisecow.local:443:<minikube-ip> https://wisecow.local/`

## CI/CD notes (GitHub Actions)

- Workflow file: `.github/workflows/ci-cd.yaml`
- Builds and pushes image to GHCR: `ghcr.io/<owner>/wisecow`
- Optional deploy: set `KUBE_CONFIG_B64` repo secret (base64 of kubeconfig)
- GHCR requires lowercase image names; update `k8s/deployment-ghcr.yaml` and the workflow `IMAGE_NAME`

## Problem Statement 2 scripts

### System Health Monitoring (Bash)

File: `scripts/system_health_monitor.sh`

Run:
```
chmod +x scripts/system_health_monitor.sh
./scripts/system_health_monitor.sh
```

Optional thresholds:
```
CPU_THRESHOLD=80 MEM_THRESHOLD=80 DISK_THRESHOLD=80 PROC_THRESHOLD=300 ./scripts/system_health_monitor.sh
```

### Log File Analyzer (Bash)

File: `scripts/log_analyzer.sh`

Run:
```
chmod +x scripts/log_analyzer.sh
./scripts/log_analyzer.sh /path/to/access.log
```

Optional:
```
TOP_N=5 ./scripts/log_analyzer.sh /var/log/nginx/access.log
```



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
