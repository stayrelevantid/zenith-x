# Technical Specification: PROJECT ZENITH-X

**Objective:** Membangun infrastruktur Cloud-Native standar (MVP) di GCP menggunakan GitOps sebagai pendekatan utama untuk deployment dan manajemen konfigurasi.

---

## 1. Cloud Infrastructure (Terraform)

Seluruh infrastruktur di-provisioning menggunakan Terraform dengan pendekatan modular:

| Resource | Detail |
| :--- | :--- |
| **Provider** | Google Cloud Platform (GCP), Region `asia-southeast2` |
| **Networking** | Custom VPC, 1 Private Subnet, Cloud NAT, Cloud Router |
| **Compute** | GKE Standard Cluster, Spot Node Pool (`e2-medium`, 3 nodes) |
| **Security** | Workload Identity enabled, IAM least-privilege |
| **State** | Remote state di Google Cloud Storage (GCS) |
| **Secrets** | Google Secret Manager (GSM) |
| **Registry** | Google Artifact Registry (GAR) untuk Docker images |

---

## 2. Kubernetes Add-ons (via ArgoCD)

Semua add-on di-deploy secara otomatis oleh ArgoCD menggunakan pola **App-of-Apps**:

| Add-on | Fungsi |
| :--- | :--- |
| **ArgoCD** | GitOps engine — sinkronisasi manifest dari Git ke cluster |
| **Traefik** | Ingress controller — routing traffic dan TLS termination |
| **Cert-Manager** | Otomasi SSL certificate dari Let's Encrypt |
| **External Secrets Operator** | Sinkronisasi secret dari GSM ke Kubernetes Secret |

**Flow Add-on Deployment:**
```
root-app.yaml → ArgoCD membaca folder apps/ → Deploy child apps secara paralel:
  ├── traefik (Helm chart)
  ├── cert-manager (Helm chart)
  ├── external-secrets (Helm chart + WIF annotation)
  ├── cluster-issuer (Let's Encrypt ClusterIssuer)
  ├── cluster-configs (ClusterSecretStore)
  └── zenith-app (Kustomize manifests)
```

---

## 3. Application (Go v1.0.2)

Aplikasi Go sederhana dengan endpoint untuk validasi infrastruktur:

| Endpoint | Response |
| :--- | :--- |
| `GET /` | `{ status, message, version, hostname, timestamp }` |
| `GET /health` | `{ status: "healthy" }` |
| `GET /secret` | `{ secret_status, secret_value }` — dari GSM via ESO |

**CI/CD Flow:**
```
Developer push ke app/ → GitHub Actions:
  1. Build Docker image (multi-stage)
  2. Push ke Artifact Registry
  3. Update image tag di k8s-manifests/overlays/testing/kustomization.yaml
  4. Commit & push tag update ke Git
  → ArgoCD detect perubahan → Auto-sync → Deploy ke GKE
```

---

## 4. Project Structure

```text
zenith-x/
├── .github/workflows/ci-cd.yaml   # CI/CD Pipeline
├── app/                            # Go app + Dockerfile
├── argocd-bootstrap/
│   ├── root-app.yaml               # Entry point ArgoCD
│   ├── apps/                       # Child app definitions
│   │   ├── traefik.yaml
│   │   ├── cert-manager.yaml
│   │   ├── external-secrets.yaml
│   │   ├── cluster-issuer.yaml
│   │   ├── cluster-configs.yaml
│   │   └── zenith-app.yaml
│   └── configs/                    # Cluster-wide resources
│       ├── cluster-issuer/
│       └── external-secrets/
├── k8s-manifests/
│   ├── base/                       # Deployment, Service, IngressRoute, ExternalSecret
│   └── overlays/testing/           # Testing env overrides (replica, image tag)
└── terraform/
    ├── modules/                    # vpc, gke, iam, wif
    ├── main.tf, variables.tf
    ├── terraform.tfvars
    └── backend.tf
```

---

## 5. Execution Phases

| Phase | Status | Deskripsi |
| :--- | :--- | :--- |
| **Phase 1 — Infra** | ✅ Done | Terraform provisioning: VPC, GKE (Spot), IAM, WIF, GAR |
| **Phase 2 — GitOps** | ✅ Done | Install ArgoCD via Helm, apply root-app.yaml |
| **Phase 3 — Core Services** | ✅ Done | ArgoCD auto-deploy: Traefik, Cert-Manager, ESO |
| **Phase 4 — App Deploy** | ✅ Done | CI/CD pipeline aktif, app v1.0.2 live, ESO terintegrasi |
| **Phase 5 — Cleanup** | ✅ Done | `terraform destroy` untuk semua infra & GCS state bucket |

---

## 6. Masalah & Solusi

| # | Masalah | Akar Penyebab | Solusi |
| :--- | :--- | :--- | :--- |
| 1 | **GKE cluster ter-recreate** setiap `terraform apply` | Terraform mendeteksi drift pada parameter yang dikelola GCP (node_version, dll) | Tambahkan `lifecycle { ignore_changes }` di resource cluster & node pool |
| 2 | **ESO gagal akses GSM** (`PermissionDenied`) | KSA `external-secrets` tidak memiliki annotation WIF (`iam.gke.io/gcp-service-account`) | Tambahkan annotation di Helm values ESO via ArgoCD, lalu restart operator |
| 3 | **Git push conflict** saat push infrastructure changes | GitHub Actions sudah commit update image tag di branch yang sama | Gunakan `git pull --rebase` sebelum push |

---

## 7. Lessons Learned

1. **Terraform + Managed Services:** GKE dikelola oleh GCP secara otomatis (auto-upgrade, node repair). Terraform harus di-konfigurasi agar **tidak mencoba mengontrol** parameter yang berubah secara otomatis. Gunakan `ignore_changes` untuk menghindari recreation yang tidak perlu.

2. **Workload Identity = KSA Annotation:** Seluruh chain WIF (IAM binding, GSA role) akan gagal jika KSA tidak memiliki annotation `iam.gke.io/gcp-service-account`. Ini adalah **single point of failure** yang paling sering terlewat.

3. **GitOps Discipline:** Semua perubahan harus melalui Git. Jika CI/CD dan developer mengubah branch yang sama, **rebase** adalah cara paling aman untuk menghindari conflict.

4. **YAML Indentation Matters:** Kesalahan indentasi kecil di Helm values (yang di-embed dalam ArgoCD Application YAML) bisa menyebabkan konfigurasi **tidak ter-apply secara silent** — tidak ada error, tapi juga tidak bekerja.

---

## 8. Constraints

- Semua resource wajib memiliki label `project: zenith-x` dan `env: testing`.
- Node pool wajib menggunakan Spot Instance (`spot = true`).
- Tidak boleh hardcode credential — gunakan `ExternalSecret` CRD.
- Ingress menggunakan Traefik `IngressRoute` CRD.