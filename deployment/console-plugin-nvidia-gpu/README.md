# Console Plugin NVIDIA GPU Helm Chart

Console Plugin NVIDIA GPU is a [dynamic plugin](https://github.com/openshift/console/blob/master/frontend/packages/console-dynamic-plugin-sdk/README.md)
for the [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift)
[console UI](https://github.com/openshift/console). It leverages the metrics of the [NVIDIA GPU operator components](https://github.com/NVIDIA/gpu-operator)
in order to serve the respective [console-extensions](https://github.com/openshift/console/blob/master/frontend/packages/console-dynamic-plugin-sdk/README.md#console-extensionsjson).

## QuickStart

### Prerequisites

- [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) - version depends on chart version (see below)
- [NVIDIA GPU operator](https://github.com/NVIDIA/gpu-operator)
- [Helm](https://helm.sh/docs/intro/install/)

**Note:** Multi-arch container images with support for amd64 and arm64 architectures are available starting from version 0.2.6.

### Version Compatibility

| Chart Version | OpenShift Version | Plugin Enablement | Notes |
|--------------|-------------------|-------------------|-------|
| 0.2.6 | 4.12 - 4.18 | Manual | Legacy version |
| 0.3.0 | 4.19+ | Manual | PatternFly v6 upgrade |
| 1.0.0 | 4.19+ | Automatic | Recommended for new installations |

**Note:** Version 1.0.0 uses a new Helm chart structure. Existing users upgrading from 0.x versions should follow the [UPGRADE.md](UPGRADE.md) migration guide.

### Deployment

#### Step 1: Add Helm Repository

```bash
$ helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu
$ helm repo update
```

#### Step 2: Install the Chart

Choose the appropriate version based on your OpenShift version:

```bash
# For OpenShift 4.19+ (recommended)
$ helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu

# For OpenShift 4.12-4.18
$ helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu --version 0.2.6
```

**Production Recommendation:** The chart defaults to a single replica. For production environments, consider deploying with 2 or more replicas for high availability and zero-downtime updates.

#### Step 3: Enable the Plugin

**For version 1.0.0:** The plugin is automatically enabled via a post-install hook. Verify with:

```bash
$ oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}" | grep console-plugin-nvidia-gpu
```

**For versions 0.2.6 and 0.3.0:** Enable the plugin manually:

```bash
# Check if a plugins field is specified
$ oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}"

# If not, run this to enable the plugin:
$ oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge

# If yes, run this to add the plugin:
$ oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
```

#### Step 4: Configure DCGM Exporter

Add the required metrics ConfigMap to the NVIDIA operator ClusterPolicy:

```bash
$ oc patch clusterpolicies.nvidia.com gpu-cluster-policy --patch '{ "spec": { "dcgmExporter": { "config": { "name": "console-plugin-nvidia-gpu" } } } }' --type=merge
```

#### View Deployed Resources

```bash
$ oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu
```

#### Optional: Disable Auto-Enablement (Version 1.0.0)

To install version 1.0.0 without automatic plugin enablement:

```bash
$ helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu --set plugin.jobs.patchConsoles.enabled=false
```

### Helm Tests

The Console Plugin NVIDIA GPU Helm chart includes tests to verify the the console plugin's
deployment. To run the tests run the following commands:

```
# install Helm chart if you have not already done so
$ helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu

# run the tests
$ helm test console-plugin-nvidia-gpu --timeout 2m
```
