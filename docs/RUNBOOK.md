# Runbook (fill this in — a teammate must rebuild from this alone)

## Provision from zero
```bash
# 1. infra
cd infra/terraform && terraform init && terraform apply
# 2. cluster
cd ../ansible && ansible-playbook -i inventory site.yml
# 3. kubeconfig
export KUBECONFIG=./kubeconfig && kubectl get nodes
# 4. platform (ingress, cert-manager, metrics-server, argocd) — exact commands:
#    ...
# 5. GitOps t# TaskApp Runbook

Run commands from the repository root unless stated otherwise.
Never commit credentials, environment files, kubeconfigs or Terraform state.

## 1. Prerequisites

Install Git, AWS CLI, Terraform matching versions.tf, Helm, kubectl,
and Python with venv support. Configure AWS credentials and verify:

```bash
aws sts get-caller-identity
```

Clone the repository and install Ansible dependencies:

```bash
git clone https://github.com/Henestoe/capstone-project.git
cd capstone-project

python3 -m venv .venv
source .venv/bin/activate
pip install -r infra/ansible/requirements.txt
ansible-galaxy collection install -r infra/ansible/requirements.yml
```

Create an SSH key if one does not already exist:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/taskapp -C taskapp
```

Do not overwrite an existing key.

## 2. Terraform state infrastructure

The state infrastructure is in infra/terraform/terraform-backend.

For an existing deployment, retain the configured remote backend.
Never initialise an empty local state to manage infrastructure that
already has remote state.

For a completely new AWS account:

1. Temporarily remove the S3 backend block from the bootstrap
   configuration so its first deployment uses local state.
2. Run the following commands:

```bash
cd infra/terraform/terraform-backend
terraform init
terraform plan
terraform apply
terraform output
```

3. Restore the bootstrap S3 backend configuration using the newly created
   bucket, region and lock table. Use bootstrap/terraform.tfstate as its key.
4. Migrate its local state:

```bash
terraform init -migrate-state
```

5. Update infra/terraform/root/backend.tf with the same bucket and table,
   keeping its separate key: dev/cluster/terraform.tfstate.

Never commit the bootstrap state or its local backup.

## 3. Provision the nodes

From the repository root, retrieve the administrator's public IP and
an Ubuntu 24.04 amd64 AMI:

```bash
curl -4 https://checkip.amazonaws.com

aws ssm get-parameter \
  --region us-east-1 \
  --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
  --query Parameter.Value \
  --output text
```

Create an ignored infra/terraform/root/terraform.tfvars file:

```hcl
ssh_cidr            = "YOUR_PUBLIC_IP/32"
ami_id              = "YOUR_AMI_ID"
ssh_public_key_path = "~/.ssh/taskapp.pub"
```

Replace both placeholders, then provision:

```bash
cd infra/terraform/root
terraform init
terraform validate
terraform plan
terraform apply
terraform output nodes
```

The defaults create one t3.medium server and two t3.small workers.

## 4. Configure Kubernetes

Update infra/ansible/inventory/hosts.yml with the new public and private
IPs. The Terraform server is named control-plane in Ansible.

Update the administrator SSH allowlist in
infra/ansible/inventory/group_vars/all.yml to match terraform.tfvars.
Keep the pinned k3s version and existing cluster settings.

Before Ansible connects for the first time, verify each server's SSH
host-key fingerprint against a trusted AWS-side source, then accept it
through an interactive SSH connection. Do not disable host-key checking.

```bash
cd infra/ansible
ansible-inventory --graph
ansible k3s_cluster -m ansible.builtin.ping

ansible-playbook site.yml --syntax-check
ansible-playbook site.yml
ansible-playbook site.yml
```

Review the second run for idempotency: no unexpected changes or failures.

The kubeconfig is stored locally at infra/ansible/kubeconfig/k3s.yaml.
Keep it private.

## 5. Open the Kubernetes tunnel

In a separate local terminal, replace CONTROL_PLANE_PUBLIC_IP:

```bash
ssh -i ~/.ssh/taskapp -N \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -L 127.0.0.1:16443:127.0.0.1:6443 \
  ubuntu@CONTROL_PLANE_PUBLIC_IP
```

Leave this terminal running. In the working terminal, from the repository root:

```bash
export KUBECONFIG="$PWD/infra/ansible/kubeconfig/k3s.yaml"
kubectl get nodes
```

The kubeconfig server address must be https://127.0.0.1:16443.
Do not expose port 6443 publicly.

## 6. Bootstrap GitOps and application secrets

Application definitions must point to the intended repository and branch.
Commit and push the manifests before bootstrapping.

```bash
cd infra/ansible
ansible-playbook bootstrap.yml
```

Argo CD installs the platform components and synchronizes TaskApp.
On a fresh cluster, some resources may initially wait for cert-manager
or application secrets.

Once the taskapp namespace exists, create an ignored .env.taskapp file
in the repository root containing:

```text
POSTGRES_PASSWORD=<strong database password>
SECRET_KEY=<strong application signing key>
```

Replace the placeholders locally. Generate separate random values with
openssl rand -hex 32. Never paste the resulting credentials into Git.

From the repository root:

```bash
chmod 600 .env.taskapp

kubectl create secret generic taskapp-secrets \
  --namespace taskapp \
  --from-env-file=.env.taskapp
```

This is the documented out-of-band Secret bootstrap.
Do not recreate it or change the database password casually on an
existing database.

If Argo CD reports a failed initial synchronization, retry a full Sync
through its interface after the prerequisites are ready.

## 7. DNS, HTTPS and verification

In GoDaddy, set the taskapp A record for hph-info.xyz to the
control-plane public IP. Remove conflicting records for that hostname.
Keep ports 80 and 443 reachable for ingress and certificate validation.

```bash
kubectl get applications -n argocd
kubectl get pods,pvc,services -n taskapp
kubectl logs -n taskapp job/taskapp-migrations
kubectl get clusterissuer letsencrypt-prod
kubectl get ingress,certificates -n taskapp

curl -vI https://taskapp.hph-info.xyz
curl https://taskapp.hph-info.xyz/api/health

kubectl top nodes
kubectl top pods -n taskapp
```

Expect healthy application Pods, a completed migration, a Bound PVC,
a ready certificate and a healthy database response.

## 8. Deploy, scale and roll back

For application changes, edit manifests, commit and push.
Argo CD applies the change; do not manually apply application manifests.

- Deploy: change the pinned image tag in the appropriate Deployment.
- Scale: change spec.replicas, retaining at least two replicas for
  frontend and backend.
- Migration: update the migration Job image with the backend release.
  Keep migrations compatible with the currently running application.

Check progress:

```bash
kubectl get applications -n argocd
kubectl rollout status deployment/backend -n taskapp
kubectl rollout status deployment/frontend -n taskapp
```

To undo an application deployment, revert its Git commit:

```bash
git revert <deployment-commit>
git push origin main
```

A Git revert does not undo database schema changes.

## 9. Failure recovery

### Worker failure or maintenance

Existing replicas on other nodes can continue serving. Kubernetes
creates replacements where resources and scheduling rules permit.
Recovery time depends on failure detection, image availability and capacity.

For the demonstrated controlled drain:

```bash
kubectl drain worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=180s

kubectl get pods -A -o wide
kubectl uncordon worker-1
```

Only permit emptyDir deletion after checking that the affected data is
disposable. Never drain the Postgres node as though its storage were replicated.

For a genuinely failed worker, check EC2 health and networking.
If replacement is necessary, review Terraform's plan, provision the
replacement, update inventory and run Ansible again.

### Failed backend Pod

```bash
kubectl get pods -n taskapp
kubectl describe pod <backend-pod> -n taskapp
kubectl logs <backend-pod> -n taskapp
kubectl logs <backend-pod> -n taskapp --previous
kubectl get events -n taskapp --sort-by=.metadata.creationTimestamp
```

Inspect configuration, database connectivity and resource limits.
Fix manifests through Git, or revert the faulty release.

### Failed migration

```bash
kubectl logs -n taskapp job/taskapp-migrations
kubectl describe job taskapp-migrations -n taskapp
```

Do not repeatedly retry a migration without checking whether it partially
changed the database. Correct the migration or use an appropriate,
reviewed downgrade. Prefer a forward-compatible fix where possible.

Restoring a database backup may be necessary for destructive changes.
This project has not implemented or tested automated backup/restore;
without a usable backup, lost data cannot be guaranteed recoverable.

### Postgres Pod failure

```bash
kubectl get pods,pvc -n taskapp
kubectl describe pod postgres-0 -n taskapp
kubectl logs postgres-0 -n taskapp
```

The StatefulSet recreates the Pod and reuses its PVC on the control plane.
Do not delete data-postgres-0. Loss of the underlying node disk is not
repaired by recreating the Pod.

### SSH or Kubernetes connection failure

Check that EC2 instances are running and inventory IPs are current.
A changed home public IP requires updating both the AWS SSH allowlist
and UFW. Use the configured control-plane Session Manager access if
SSH is locked out, then reconcile the change in Terraform and Ansible.

For localhost:16443 connection errors, check that the SSH tunnel is running.akes over
kubectl apply -f gitops/   # then Argo syncs the app
```

## Day-2 operations
- **Scale a tier:** … (and note: prefer a git commit so Argo stays the source of truth)
- **Roll back a bad deploy:** …
- **Run a new migration safely:** …
- **Rotate a secret:** …

## Failure recovery (you'll demo one of these live)
- **A worker node dies / is drained:** what happens, what you do, expected recovery time. …
  ```bash
  kubectl drain <node> --ignore-daemonsets --delete-emptydir-data   # the live-demo command
  ```
- **A backend Pod crashloops:** how you diagnose (`logs --previous`, `describe`, events). …
- **A bad migration:** how you recover the DB. …
- **Postgres Pod is rescheduled:** prove the PVC re-attaches and data is intact. …
