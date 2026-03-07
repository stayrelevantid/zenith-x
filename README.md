# 🚀 Project Zenith-X

> **Standardized MVP Cloud-Native Infrastructure on GCP using GitOps**

---

## 📐 Architecture Overview

```text
zenith-x/
├── terraform/                # Infrastructure as Code
│   ├── modules/              # Reusable modules (vpc, gke, iam)
│   ├── main.tf               # Root module (APIs, GAR, GSM)
│   ├── variables.tf          # Configurable inputs
│   ├── terraform.tfvars      # Environment values
│   ├── backend.tf            # GCS Remote State config
│   └── state-bootstrap/      # One-time GCS bucket provisioning
├── argocd-bootstrap/         # ArgoCD App-of-Apps
│   ├── root-app.yaml         # Root application manifest
│   ├── apps/                 # Child apps (traefik, cert-manager, eso)
│   └── configs/              # Supporting configs (ClusterIssuer)
├── k8s-manifests/            # Application manifests (GitOps Repo)
│   ├── base/                 # Base k8s resources (Deploy, Service, Ingress)
│   └── overlays/             # Environment-specific patches
└── .github/workflows/        # CI/CD Pipelines
    └── ci-cd.yaml            # Build, Push to GAR & Update Manifest
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Cloud** | Google Cloud Platform (GCP) |
| **IaC** | Terraform |
| **Compute** | GKE Standard Cluster + Spot VMs (`e2-medium`) |
| **Networking** | Custom VPC, Private Subnet, Cloud NAT |
| **GitOps** | ArgoCD (App-of-Apps pattern) |
| **Ingress** | Traefik |
| **SSL** | Cert-Manager + Let's Encrypt |
| **Secrets** | Google Secret Manager + External Secrets Operator |
| **Registry** | Google Artifact Registry |
| **CI/CD** | GitHub Actions |

---

## 🗺️ Execution Phases

| Phase | Description | Status |
|---|---|---|
| **Phase 1** – Infra | `terraform apply` – VPC, GKE Spot, IAM, GAR, GSM | ✅ Done |
| **Phase 2** – GitOps | Install ArgoCD via Helm + App-of-Apps bootstrap | ✅ Done |
| **Phase 3** – Core Services | ArgoCD deploys Traefik, Cert-Manager, ESO | ✅ Auto-syncing |
| **Phase 4** – App Deployment | GitHub Actions builds & pushes image, ArgoCD syncs | ⏳ Pending |
| **Phase 5** – Cleanup | `terraform destroy` | ⏳ Pending |

---

## ⚡ Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.x
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- GCP project with billing enabled

### Phase 1 – Provision Infrastructure

```bash
# 1. Authenticate with GCP
gcloud auth application-default login

# 2. (First time only) Bootstrap the GCS state bucket
cd terraform/state-bootstrap
terraform init && terraform apply

# 3. Provision all infrastructure
cd ../
terraform init
terraform plan
terraform apply
```

### Phase 2 – Install ArgoCD

```bash
# Connect to the GKE cluster
gcloud container clusters get-credentials zenith-x-cluster-testing \
  --region asia-southeast2 \
  --project stayrelevantid

# Install ArgoCD via Helm
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set configs.params."server.insecure"=true \
  --wait

# Bootstrap core services (Traefik, Cert-Manager, ESO)
kubectl apply -f argocd-bootstrap/root-app.yaml
```

### Access ArgoCD UI

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
# User: admin
# Pass: kubectl -n argocd get secret argocd-initial-admin-secret \
#         -o jsonpath="{.data.password}" | base64 -d
```

---

## 🔒 Key Constraints

- **No hardcoded credentials** – all secrets go through GSM + External Secrets Operator
- **Spot VMs** – `spot = true` on all node pools to minimize cost
- **Workload Identity** – pods authenticate to GCP APIs without service account keys
- **Ingress** – Traefik `IngressRoute` or standard Ingress with Traefik annotations
- **Labels** – all resources tagged with `project: zenith-x` and `env: testing`

---

## 📦 GCP Resources Created

| Resource | Name |
|---|---|
| GKE Cluster | `zenith-x-cluster-testing` |
| Node Pool | `zenith-x-spot-pool-testing` (Spot, `e2-medium`) |
| VPC | `zenith-x-vpc` |
| Subnet | `zenith-x-subnet` |
| Service Account | `zenith-x-gke-sa` |
| GCS State Bucket | `zenith-x-tfstate-<id>` |
| Artifact Registry | `zenith-x-repo` |

---

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

> ⚠️ This will destroy all GCP resources. Run with caution.
