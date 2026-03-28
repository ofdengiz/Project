# ClearRoots Foundation - AWS Kubernetes Infrastructure

This project deploys a lightweight Kubernetes environment on AWS and publishes
the ClearRoots Foundation website over HTTPS.

## Architecture

- 1 EC2 master node
- 1 EC2 worker node
- Route53 DNS record for `clearroots.omerdengiz.com`
- Elastic IP attached to the worker node
- Caddy on the worker for automatic HTTPS with Let's Encrypt
- Custom Docker image for the website
- S3 backend for Terraform state, created manually outside Terraform

## Files

- [main.tf](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/main.tf): EC2, IAM, Elastic IP, security group
- [route53.tf](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/route53.tf): Route53 A record
- [deployment.yaml](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/deployment.yaml): Kubernetes deployment
- [service.yaml](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/service.yaml): Kubernetes NodePort service
- [worker.sh](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/worker.sh): worker bootstrap and Caddy HTTPS setup
- [master.sh](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/master.sh): master bootstrap and manifest generation
- [Dockerfile](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/Dockerfile): web image build
- [site/index.html](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/site/index.html): website content
- [s3.tf](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/s3.tf): note about manual backend bucket management

## Manual S3 backend setup

Create the Terraform state bucket manually in AWS first, then use the existing
[backend.hcl](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/backend.hcl):

```bash
terraform init -backend-config=backend.hcl
```

## Build and publish the image

Build the image locally from this folder:

```bash
docker build -t clearroots-web:latest .
```

Push it to a public registry, then set `container_image` in
[variables.tf](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/variables.tf)
to that image URI before `terraform apply`.

Example:

```hcl
variable "container_image" {
  default = "docker.io/your-user/clearroots-web:latest"
}
```

If you want the exact generated artwork on the page, place it here before
building:

```text
site/assets/clearroots-hero.png
```

The site already references that file and falls back to an SVG illustration if
it is missing.

## Deploy

1. Review [variables.tf](C:/Algonquin/Winter2026/Emerging_Tech/Project/WebServer/variables.tf).
2. Run:

```bash
terraform plan
terraform apply
```

3. SSH to the master and deploy the manifests:

```bash
kubectl apply -f /home/ubuntu/clearroots/
```

## HTTPS behavior

- Route53 points the domain to the worker Elastic IP
- Caddy listens on ports 80 and 443
- Caddy automatically requests and renews the Let's Encrypt certificate
- Caddy proxies HTTPS traffic to the Kubernetes service on `127.0.0.1:30080`

## Expected result

After DNS propagation and bootstrap complete, the site should be available at:

```text
https://clearroots.omerdengiz.com
```
