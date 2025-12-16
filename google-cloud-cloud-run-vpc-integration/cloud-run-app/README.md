# Cloud Run Proxy Application

A simple Flask-based proxy application that forwards HTTP requests to an on-premises server via VPN.

## Overview

This application acts as a proxy, forwarding all incoming requests to `http://192.168.1.110:80`. It's designed to run on Cloud Run with direct VPC egress, allowing it to reach on-premises resources through the VPN tunnel.

## Files

- `main.py` - Flask application that proxies requests
- `requirements.txt` - Python dependencies
- `Dockerfile` - Container image definition
- `.dockerignore` - Files to exclude from Docker build

## Building and Deploying

### Build the Docker image

```bash
# Build locally
docker build -t cloud-run-proxy .

# Tag for Google Container Registry
docker tag cloud-run-proxy gcr.io/YOUR_PROJECT_ID/cloud-run-proxy

# Push to GCR
docker push gcr.io/YOUR_PROJECT_ID/cloud-run-proxy
```

### Deploy to Cloud Run

You can deploy this using the Terraform configuration in the parent directory, or manually:

```bash
gcloud run deploy cloud-run-proxy \
  --image gcr.io/YOUR_PROJECT_ID/cloud-run-proxy \
  --region europe-west4 \
  --vpc-connector YOUR_VPC_CONNECTOR \
  --vpc-egress all-traffic
```

## Configuration

The target URL (`192.168.1.110:80`) is hardcoded in `main.py`. To change it:

1. Modify the `TARGET_URL` variable in `main.py`
2. Rebuild and redeploy the container

Alternatively, you can make it configurable via environment variables (see below).

## Environment Variables (Optional Enhancement)

To make the target URL configurable, you could modify `main.py`:

```python
import os
TARGET_URL = os.getenv("TARGET_URL", "http://192.168.1.110:80")
```

Then set it when deploying:

```bash
gcloud run deploy cloud-run-proxy \
  --set-env-vars TARGET_URL=http://192.168.1.110:80
```

## Testing

Once deployed, test the proxy:

```bash
# Get the Cloud Run service URL
SERVICE_URL=$(gcloud run services describe cloud-run-proxy --region europe-west4 --format 'value(status.url)')

# Test the proxy
curl $SERVICE_URL/
```

## Notes

- The application listens on port 8080 (Cloud Run default)
- Timeout is set to 5 seconds for upstream requests
- Errors are returned as 502 status codes
- The application uses gunicorn as the WSGI server for production

