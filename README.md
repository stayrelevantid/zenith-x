# Project Zenith-X 🚀

Zenith-X adalah project lab untuk membangun infrastruktur Cloud-Native di Google Cloud Platform (GCP) menggunakan pendekatan **GitOps**. Seluruh proses — mulai dari provisioning server, deploy aplikasi, hingga manajemen secret — diotomasi sepenuhnya menggunakan Terraform, ArgoCD, dan GitHub Actions.

**Live URL:** [https://masmasdeploy.my.id](https://masmasdeploy.my.id)

---

## 🏗 Architecture Overview

```mermaid
graph LR
    Dev[Developer] -->|git push| GitHub

    subgraph "GitHub"
        GitHub -->|Trigger| GHA[GitHub Actions]
    end

    subgraph "Google Cloud Platform"
        GHA -->|1. Build & Push Image| GAR[Artifact Registry]
        GHA -->|2. Update Image Tag| GitHub

        subgraph "GKE Cluster"
            ArgoCD -->|3. Detect Change & Sync| App[Go App v1.0.2]
            App -->|Pull Image| GAR
            Traefik[Traefik Ingress] -->|Route Traffic| App
            CertMgr[Cert-Manager] -->|Issue SSL| Traefik
            ESO[External Secrets Operator] -->|Fetch Secret| GSM[Secret Manager]
            ESO -->|Inject as Env Var| App
        end
    end
```

**Alur kerja secara sederhana:**
1. Developer push kode ke GitHub.
2. GitHub Actions otomatis build Docker image dan push ke Artifact Registry.
3. GitHub Actions update tag image di manifest Kubernetes, lalu commit balik ke Git.
4. ArgoCD mendeteksi perubahan di Git dan otomatis deploy versi terbaru ke GKE.
5. Traefik mengarahkan traffic dari internet ke aplikasi, dengan SSL dari Let's Encrypt.
6. External Secrets Operator mengambil secret dari Google Secret Manager dan inject ke aplikasi.

---

## 🛠 Tech Stack

| Kategori | Teknologi |
| :--- | :--- |
| **Cloud Provider** | Google Cloud Platform (GCP) |
| **Infrastructure as Code** | Terraform (modular: VPC, GKE, IAM, WIF) |
| **Kubernetes** | GKE Standard Cluster, Spot Node Pool (`e2-medium`) |
| **GitOps Engine** | ArgoCD (App-of-Apps pattern) |
| **Ingress Controller** | Traefik (IngressRoute CRD) |
| **SSL/TLS** | Cert-Manager + Let's Encrypt (ClusterIssuer) |
| **Secret Management** | External Secrets Operator + Google Secret Manager |
| **CI/CD** | GitHub Actions + Workload Identity Federation (keyless auth) |
| **Application** | Golang (chi router), Docker multi-stage build |

---

## 📁 Project Structure

```text
zenith-x/
├── .github/workflows/        # CI/CD: build, push, update manifest
│   └── ci-cd.yaml
├── app/                      # Go application source code + Dockerfile
│   ├── main.go               # Endpoints: /, /health, /secret
│   └── Dockerfile
├── argocd-bootstrap/         # ArgoCD GitOps bootstrap
│   ├── root-app.yaml         # Root Application (App-of-Apps)
│   ├── apps/                 # Child apps: traefik, cert-manager, eso, zenith-app
│   └── configs/              # Cluster-wide configs: ClusterIssuer, ClusterSecretStore
├── k8s-manifests/            # Kubernetes manifests (Kustomize)
│   ├── base/                 # Deployment, Service, IngressRoute, ExternalSecret
│   └── overlays/testing/     # Testing environment overrides
└── terraform/                # GCP Infrastructure as Code
    ├── modules/              # vpc, gke, iam, wif
    ├── main.tf, variables.tf, terraform.tfvars
    └── backend.tf            # GCS remote state
```

---

## 🚀 Cara Menjalankan (Step-by-Step)

### Prasyarat
- Google Cloud SDK (`gcloud`) sudah terinstal dan terautentikasi.
- Terraform, Helm, dan kubectl sudah terinstal.
- Repository GitHub sudah disiapkan.

### Step 1 — Provisioning Infrastructure
```bash
cd terraform
terraform init
terraform apply
```
> Ini akan membuat: VPC, GKE Cluster, Artifact Registry, Service Account, dan Workload Identity Pool.

### Step 2 — Connect ke GKE Cluster
```bash
gcloud container clusters get-credentials zenith-x-cluster-testing --region asia-southeast2
```

### Step 3 — Install ArgoCD & Bootstrap GitOps
```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
helm install argocd argo/argo-cd -n argocd \
  --set server.service.type=ClusterIP \
  --set configs.params."server.insecure"=true --wait

# Apply Root App → ArgoCD akan otomatis deploy semua child apps
kubectl apply -f argocd-bootstrap/root-app.yaml
```

### Step 4 — Setup GitHub Secrets (untuk CI/CD)
Di **GitHub → Settings → Secrets → Actions**, tambahkan:
- `WIF_PROVIDER` — Full resource name dari WIF Provider.
- `WIF_SERVICE_ACCOUNT` — Email service account (contoh: `zenith-x-gke-sa@stayrelevantid.iam.gserviceaccount.com`).

### Step 5 — Test Deployment
Push perubahan ke folder `app/`, lalu GitHub Actions akan otomatis:
1. Build image → Push ke GAR
2. Update image tag di `k8s-manifests/overlays/testing/kustomization.yaml`
3. ArgoCD sync otomatis → Aplikasi ter-deploy

**Akses ArgoCD UI:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Buka: https://localhost:8080 | User: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 🔗 Endpoints

| Endpoint | Deskripsi |
| :--- | :--- |
| `/` | Info aplikasi: version, hostname, timestamp |
| `/health` | Health check (status: healthy) |
| `/secret` | Menampilkan secret dari Google Secret Manager (test ESO) |

---

## 🐛 Masalah yang Dihadapi & Solusi

### 1. GKE Cluster Ter-recreate Terus oleh Terraform
- **Masalah:** Setiap kali `terraform apply` dijalankan (baik manual maupun via CI/CD), Terraform mendeteksi perubahan kecil pada cluster (misalnya auto-upgrade, label internal GCP) dan memutuskan untuk **destroy lalu recreate** seluruh cluster. Ini sangat memakan waktu (~15 menit per recreate) dan menghancurkan semua yang sudah di-deploy.
- **Akar Masalah:** Terraform membandingkan state file dengan kondisi aktual cluster. Parameter yang dikelola otomatis oleh GCP (seperti `node_version`, `node_config`) selalu berubah, sehingga Terraform menganggap ada "drift".
- **Solusi:** Menambahkan blok `lifecycle { ignore_changes = [...] }` pada resource `google_container_cluster` dan `google_container_node_pool` di Terraform. Ini memberitahu Terraform untuk mengabaikan perubahan pada parameter tertentu yang dikelola oleh GCP.
- **Lesson:** Untuk managed services seperti GKE, selalu gunakan `ignore_changes` agar Terraform tidak mencoba "memperbaiki" hal-hal yang memang dikelola oleh cloud provider.

### 2. External Secrets Gagal: Permission Denied
- **Masalah:** External Secrets Operator (ESO) gagal mengambil secret dari Google Secret Manager dengan error `PermissionDenied: secretmanager.versions.access denied`.
- **Akar Masalah:** Meskipun IAM role (`roles/secretmanager.secretAccessor`) sudah benar di level GSA, dan IAM binding WIF sudah benar, ternyata **Kubernetes ServiceAccount (KSA) tidak memiliki annotation** `iam.gke.io/gcp-service-account`. Tanpa annotation ini, Workload Identity tidak tahu KSA mana yang boleh "menyamar" sebagai GSA.
- **Solusi:** Menambahkan annotation WIF di Helm values untuk ESO melalui ArgoCD manifest. Setelah itu, restart deployment ESO agar pod menggunakan token baru.
- **Lesson:** Ketika WIF gagal, **selalu cek annotation KSA terlebih dahulu**. Ini adalah titik kegagalan paling umum. Kesalahan indentasi kecil di YAML bisa menyebabkan annotation tidak ter-apply secara silent.

### 3. Git Push Conflict dari CI/CD
- **Masalah:** Saat push perubahan infrastructure ke Git, terjadi conflict karena GitHub Actions sudah melakukan commit (update image tag) di branch yang sama.
- **Solusi:** Selalu lakukan `git pull --rebase` sebelum push untuk mengintegrasikan perubahan dari remote.

---

## 🗑 Cleanup

```bash
cd terraform
terraform destroy
```
> ⚠️ Ini akan menghapus **semua** resource GCP termasuk GKE cluster, VPC, dan data di dalamnya.

---

Managed by **Antigravity AI**
