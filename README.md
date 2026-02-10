# tw-tazama-infra

Kubernetes GitOps scaffold for Tazama, structured to mirror `stg-hub-liberia-gitops`:

- Ansible bootstraps cluster + Argo CD.
- Argo CD Applications are rendered from Ansible templates.
- Workloads are grouped under `apps/*` and managed with Kustomize.

## How The Company Pattern Works (From `stg-hub-liberia-gitops`)

1. Ansible playbooks run in sequence (`1.microk8s_setup.yml`, `2.argocd_setup.yml`, ...).
2. Argo CD is installed on the cluster and connected to this Git repository.
3. `apps_setup` renders one Argo `Application` per app folder with sync waves.
4. Argo reconciles manifests under `apps/*` continuously.

## Structure In This Repository

```text
ansible/
  1.microk8s_setup.yml
  2.argocd_setup.yml
  3.apps_setup.yml
  group_vars/all.yml
  inventory.ini
  roles/
    common/
    microk8s_cluster/
    kubeconfig/
    argocd_setup/
    apps_setup/
apps/
  base-utils/
  tazama-platform/
  tazama-config/
  tazama-auth/
  tazama-core/
  tazama-rules/
  tazama-relay/
  tazama-observability/
  tazama-ui/
  tazama-utils/
```

## Docker Compose To GitOps Mapping (From `Full-Stack-Docker-Tazama`)

- `docker-compose.base.infrastructure.yaml` -> `apps/tazama-platform`
- `docker-compose.base.auth.yaml` + `docker-compose.dev.auth.yaml` -> `apps/tazama-auth`
- `docker-compose.hub.core.yaml` / `docker-compose.dev.core.yaml` -> `apps/tazama-core`
- `docker-compose.hub.rules.yaml` + `docker-compose.full.rules.yaml` -> `apps/tazama-rules`
- `docker-compose.hub.relay.yaml` / `docker-compose.dev.relay.yaml` -> `apps/tazama-relay`
- `docker-compose.hub.logs.base.yaml` -> `apps/tazama-observability`
- `docker-compose.hub.ui.yaml` -> `apps/tazama-ui`
- `docker-compose.utils.*.yaml` -> `apps/tazama-utils`
- Shared env/auth/sql/hasura assets -> `apps/tazama-config`

## Deployment Flow

From `ansible/`:

```bash
ansible-playbook -i inventory.ini 1.microk8s_setup.yml
ansible-playbook -i inventory.ini 2.argocd_setup.yml
ansible-playbook -i inventory.ini 3.apps_setup.yml
```

## Run On K3s (Local Cluster)

For K3s you normally **skip** `1.microk8s_setup.yml` and deploy apps directly or via ArgoCD.

### 1) Prerequisites

- Running K3s cluster
- `kubectl`, `helm`, `ansible-playbook`
- kubeconfig in `~/.kube/config`

Use:

```bash
export KUBECONFIG="$HOME/.kube/config"
kubectl get nodes
```

### 2) Direct Deploy To K3s (Fastest Way)

This applies all manifests from local files (no ArgoCD requirement):

```bash
./scripts/deploy-k3s-direct.sh
```

Then verify:

```bash
kubectl -n tazama get deploy,sts,pod
```

### 3) ArgoCD Deploy On K3s (GitOps Mode)

If you want full GitOps behavior on K3s:

1. Update `ansible/group_vars/all.yml` with a reachable `git_url` and branch.
2. Use local inventory: `ansible/inventory.k3s-local.ini`.
3. Run:

```bash
cd ansible
export ANSIBLE_LOCAL_TEMP=/tmp/ansible-local
export ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote
ansible-playbook -i inventory.k3s-local.ini 2.argocd_setup.yml
ansible-playbook -i inventory.k3s-local.ini 3.apps_setup.yml
```

If your environment requires sudo for package/binary installation, run with appropriate privileges.

## Environment-Specific Values To Update

Before real deployment, update:

- `ansible/inventory.ini`
- `ansible/group_vars/all.yml`
- image tags and hostnames in `apps/*`
- ingress/storage class settings for your cluster

## Notes

This is an infrastructure baseline aligned to your company GitOps style. It is intentionally explicit and modular so you can evolve each app folder independently.

For this environment, one known cluster baseline issue may remain unrelated to this repository: `kube-system/metrics-server` readiness can fail if kubelet metrics endpoint connectivity is blocked.
