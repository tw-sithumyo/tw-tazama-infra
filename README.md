# tw-tazama-infra

Kubernetes GitOps scaffold for Tazama, structured to mirror `stg-hub-liberia-gitops`:

- Ansible bootstraps cluster + Argo CD.
- Argo CD Applications are rendered from Ansible templates.
- Workloads are grouped under `apps/*` and managed with Kustomize.

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

### 2.1) Access Demo UI On K3s

The UI service is internal (`ClusterIP`), so use port-forwarding from your machine.

Run each in a separate terminal:

```bash
export KUBECONFIG="$HOME/.kube/config"
kubectl -n tazama port-forward svc/ui 3001:3001
kubectl -n tazama port-forward svc/tms 5000:3000
kubectl -n tazama port-forward svc/admin-service 5100:3100
```

Open:

```text
http://127.0.0.1:3001
```

By default, UI backend URLs are browser-local:
- `NEXT_PUBLIC_TMS_SERVER_URL=http://localhost:5000`
- `NEXT_PUBLIC_ADMIN_SERVICE_HOSTING=http://localhost:5100`

Keep all port-forward terminals running while using the UI.

If you cannot connect to `3001`:

```bash
export KUBECONFIG="$HOME/.kube/config"
kubectl -n tazama get pods,svc | rg 'ui|tms|admin-service'
kubectl -n tazama port-forward svc/ui 3001:3001
```

- Use `127.0.0.1` explicitly: `http://127.0.0.1:3001`.
- Keep the `port-forward` command running (do not close that terminal).
- If `3001` is already in use, choose another local port, for example:
  `kubectl -n tazama port-forward svc/ui 13001:3001` then open `http://127.0.0.1:13001`.

If your browser is on a different machine from the K3s host:

```bash
kubectl -n tazama port-forward --address 0.0.0.0 svc/ui 3001:3001
kubectl -n tazama port-forward --address 0.0.0.0 svc/tms 5000:3000
kubectl -n tazama port-forward --address 0.0.0.0 svc/admin-service 5100:3100
```

Then open `http://<k3s-host-ip>:3001` from that other machine.

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
