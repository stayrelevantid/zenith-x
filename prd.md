# Technical Specification: PROJECT ZENITH-X

**Objective**: Build a Standardized MVP Cloud-Native Infrastructure on GCP using GitOps.

## 1. Cloud Infrastructure (Terraform)
- **Provider**: Google Cloud Platform (GCP).
- **Networking**: Custom VPC, 1 Private Subnet, Cloud NAT, and Cloud Router.
- **Compute**: GKE Standard Cluster with a Spot VM Node Pool (machine type: `e2-medium`).
- **Security**: Enable Workload Identity on GKE.
- **Backend**: Remote State using Google Cloud Storage (GCS).
- **Secrets**: Setup Google Secret Manager (GSM).
- **Registry**: Create Google Artifact Registry (GAR) for Docker images.

## 2. Kubernetes Add-ons (Helm & ArgoCD)
- **ArgoCD**: Core GitOps engine (App-of-Apps pattern).
- **Ingress**: Traefik (Custom Resources/CRD support).
- **SSL**: Cert-Manager with Let's Encrypt (ClusterIssuer).
- **Secrets**: External Secret Operator (ESO) to sync GSM to K8s Secrets.

## 3. Project Structure (Best Practice)
```text
zenith-x/
├── terraform/                # Infrastructure as Code
│   ├── modules/              # Reusable modules (vpc, gke, iam)
│   ├── main.tf               # Root module
│   ├── variables.tf          # Configurable inputs
│   ├── terraform.tfvars      # Environment values
│   └── backend.tf            # GCS Remote state config
├── argocd-bootstrap/         # Root App-of-Apps manifest
│   ├── apps/                 # Child applications (traefik, cert-manager, eso)
│   └── projects/             # ArgoCD project definitions
├── k8s-manifests/            # Application manifests (GitOps Repo)
│   ├── overlays/             # Environment specific (testing)
│   └── base/                 # Base k8s resources (Deploy, Service, Ingress)
└── .github/workflows/        # CI/CD Pipelines
    └── ci-cd.yaml            # Build, Push to GAR, & Update Manifest
```

## 4. Execution Phases (Workflow)
- **Phase 1 (Infra)**: `terraform init` -> `terraform apply`. Fokus pada networking, GKE Spot, dan IAM Roles untuk Workload Identity.
- **Phase 2 (GitOps)**: Install ArgoCD via Helm. Point ArgoCD ke folder `argocd-bootstrap/`.
- **Phase 3 (Core Services)**: ArgoCD otomatis men-deploy Traefik, Cert-Manager, dan ESO berdasarkan manifest di Git.
- **Phase 4 (App Deployment)**: GitHub Actions memicu build image ke GAR dan mengupdate tag di `k8s-manifests/`. ArgoCD melakukan sinkronisasi otomatis.
- **Phase 5 (Cleanup)**: Prosedur manual `terraform destroy` dari terminal lokal.

## 5. Specific Constraints for AI Generator
- **Labeling**: All resources must have label `project: zenith-x` and `env: testing`.
- **Spot Instances**: Use `spot = true` and `preemptible = true` in GKE node pool configuration.
- **Secret Management**: Do NOT hardcode any credentials. Use `ExternalSecret` CRD.
- **Ingress**: Use Traefik `IngressRoute` or standard Ingress with Traefik annotations.