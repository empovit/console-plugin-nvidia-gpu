# Migrating to Console Plugin NVIDIA GPU 1.0.0

This guide is for **existing users** migrating from version 0.x to 1.0.0.

---

## What Changed

Version 1.0.0 introduces a new Helm chart structure aligned with the official OpenShift console plugin template.

**Chart Structure:**
- All plugin configuration moved under `plugin:` key
- New ServiceAccount settings
- Auto-enablement configuration added

**New Features:**
- Plugin automatically enables itself (no manual `oc patch` needed)
- Two dedicated ServiceAccounts created automatically
- Enhanced security with restricted pod security contexts

**Default Value Changes:**
- `imagePullPolicy`: Always → IfNotPresent
- `resources.requests`: none → 10m CPU, 50Mi memory
- Security contexts: Now enforced by default

**Requirements:**
- OpenShift 4.19+ required

---

## Migration Steps

### 1. Export Current Configuration

```bash
helm get values -n nvidia-gpu-operator console-plugin-nvidia-gpu > old-values.yaml
```

### 2. Convert Values Structure

| Old (0.x) | New (1.0.0) |
|-----------|-------------|
| `replicaCount` | `plugin.replicas` |
| `image.repository` | `plugin.image` |
| `image.tag` | `image.tag` |
| `image.pullPolicy` | `plugin.imagePullPolicy` |
| `imagePullSecrets` | `plugin.imagePullSecrets` |
| `resources` | `plugin.resources` |
| `nodeSelector` | `plugin.nodeSelector` |
| `tolerations` | `plugin.tolerations` |
| `affinity` | `plugin.affinity` |
| `podSecurityContext` | `plugin.podSecurityContext` |
| `containerSecurityContext` | `plugin.containerSecurityContext` |

New settings: `plugin.serviceAccount`, `plugin.jobs.patchConsoles`

Create a `new-values.yaml` file with your converted configuration.

### 3. Backup (Recommended)

Before proceeding, backup your current deployment configuration in case you need to reference it later.

### 4. Uninstall Old Version

Uninstall the existing chart from the cluster.

### 5. Install New Version

Install the new version using your converted values file.
