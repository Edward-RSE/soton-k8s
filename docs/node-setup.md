# Node Setup

To add a new node to the K3s cluster, it has to be configured. This is detailed in the following document.

## Network and firewall configuration

Before K3s can be installed, the network and firewall settings of a new node need to be configured. There are a number
of important ports which need to be opened and, most importantly, the Flannel CNI network plugin (using the VXLAN
backend in RHEL) need to be enabled as this is how pod-to-pod communication happens.

The following commands need to be run to add the CNI bridge interface and Flannel VXLAN interface to the trusted zone,
otherwise pod-to-pod and pod-to-service communication cannot happen. This is because data is sent across these virtual
interfaces.

```bash
firewall-cmd --permanent --zone=trusted --add-interface=cni0
firewall-cmd --permanent --zone=trusted --add-interface=flannel.1
```

We also need to configure the firewall to whitelist two internal ranges which are used to by K3s.

```bash
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16
```

The first range is used by the pod network (the IP addresses assigned to pods) and the second is for services (cluster
IPs). We need to treat traffic from this range as being trusted, otherwise pods and services cannot communicate.

The final thing we need to configure is to enable NAT (network address translation/IP masquerading), which allows pods
to reach external networks using the host's IP address. This is required for outbound connectivity.

```bash
firewall-cmd --permanent --zone=public --add-masquerade
```

These ports also need to be opened for cluster operation.

| Port | Protocol | Purpose |
| ---- | -------- | ------- |
| 6443 | TCP/UDP | Kubernetes API server |
| 10250 | TCP | Kublet API (e.g. metrics) |
| 8472 | UDP | Flannel VXLAN (pod-to-pod, pod-to-service) |
| 9500, 9501, 9502 | TCP | Longhorn engine, replica and instance manager |
| 5665 | TCP | Monitoring agent |
| 443 | TCP | HTTPS (ingress/API) |
| 10000 - 30000 | TCP | NodePort service range, used by Longhorn |

## NVIDIA driver and CUDA Toolkit

For version CUDA 13.3, version >= 610.43.02 of the Open Kernel drivers are required. Use the Open Kernel drivers and not
the proprietary drivers. Instructions are available here: <https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/red-hat-enterprise-linux.html#rhel-installation>.

Install the NVIDIA driver and Open Kernel Modules:

```bash
sudo bash
arch=x86_64 && export arch
distro=rhel9 && export distro

dnf install kernel-devel-matched kernel-headers subscription-manager repos --enable=rhel-9-for-$arch-appstream-rpms \
    subscription-manager repos --enable=rhel-9-for-$arch-baseos-rpms  \
    subscription-manager repos --enable=codeready-builder-for-rhel-9-$arch-rpms

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
dnf clean expire-cache

dnf module enable nvidia-driver:open-dkms
dnf install nvidia-open
reboot
```

Once the system has restarted, install the latest version of the CUDA Toolkit

```bash
dnf install cuda-toolkit
```

Check that all works with `nvidia-smi`, where you should see something like this:

```output
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 610.43.02              KMD Version: 610.43.02     CUDA UMD Version: 13.3     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Quadro RTX 8000                On  |   00000000:3B:00.0 Off |                    0 |
| N/A   38C    P8             31W /  250W |       0MiB /  46080MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   1  Quadro RTX 8000                On  |   00000000:5E:00.0 Off |                    0 |
| N/A   56C    P0             77W /  250W |    1607MiB /  46080MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   2  Quadro RTX 8000                On  |   00000000:B1:00.0 Off |                    0 |
| N/A   37C    P8             32W /  250W |       0MiB /  46080MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   3  Quadro RTX 8000                On  |   00000000:D9:00.0 Off |                    0 |
| N/A   47C    P0             74W /  250W |     549MiB /  46080MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
```

## Installing and configuring K3s

You can follow the installation [quick-start guide](https://docs.k3s.io/quick-start) and other installation
instrunctions to install K3s. However, installation can also be handled by a one-liner to use the default configuration:

```bash
curl -sfL https://get.k3s.io | sh -
```

This will install K3s and configure a K3s service which will automatically restart on reboots. It also installs all the
necessary K8s utilities, such as `kubectl`. The default configuration will set up a single-node configuration, with the
control plane and worker node workloads running on the same machine. Additinal "agent" nodes can be added to the cluster
using the same script.

You can verify that everything is working by running the following command, which should show the system containers
responsible for running the cluster.

```bash
$ kubectl get pods -A                                                           [10:08]
NAMESPACE     NAME                                      READY   STATUS      RESTARTS       AGE
kube-system   coredns-7f496c8d7d-q2jgx                  1/1     Running     1 (144m ago)   25h
kube-system   helm-install-traefik-629wm                0/1     Completed   1              25h
kube-system   helm-install-traefik-crd-s4tlb            0/1     Completed   0              25h
kube-system   local-path-provisioner-578895bd58-nbxgb   1/1     Running     1 (144m ago)   25h
kube-system   metrics-server-7b9c9c4b9c-fcxcp           1/1     Running     1 (144m ago)   25h
kube-system   nvidia-device-plugin-daemonset-r5f8h      1/1     Running     1 (18h ago)    24h
kube-system   svclb-traefik-70f9e36b-87knb              2/2     Running     2 (144m ago)   25h
kube-system   traefik-6f5f87584-dkznx                   1/1     Running     1 (144m ago)   25h
```

Chances are, you will be greeted by the follow error when you try to use `kubectl` the first time.

```
ARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml, please start the server with --write-kubeconfig-mode to modify kube config permissions
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

This occurs because the default K3 sconfiguration file is owned by root and in a restricted directory. You can either
always use `sudo` when running `kubectl` (like with Docker when you haven't configured rootless access), set the file
permission to 600 or create a user-specific configuration file.

### Enabling GPUs in the k3s cluster

K3s supports managing GPU resources. However, there is some leg work we have to do first. We need to:

1. Install the NVIDIA Container Runtime
2. Install the NVIDIA device plugin for K8s
3. Set the default container runtime for K3s to the NVIDIA container runtime

To install the container runtime, we have to add the NVIDIA repositories to the package manager (this assumes you have
Curl and GPG installed):

```bash
$ curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && sudo apt update
```

Now we can install the packages required:

```bash
$ export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.2-1
$ sudo apt install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-runtime
```

Once this is installed, restart the K3s service. If everything has gone to plan, K3s will automatically add the NVIDIA
container runtime to the containerd configuration. This can be confirmed by grep'ing for nvidia in the K3s containerd
configuration file:

```bash
sudo systemctl restart k3s && grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

The final two steps are to installed the NVIDIA device plugin for K8s and set the NVIDIA container runtime as the
default runtime. To install the plugin, run the following command:

```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.17.1/deployments/static/nvidia-device-plugin.yml
```

Confirmation installation by looking at the kube-system pods:

```bash
$ kubectl get pods -n kube-system | grep nvidia
nvidia-device-plugin-daemonset-r5f8h      1/1     Running     2 (63m ago)   28h
```

Finally, we can check that the GPUs have been found by K3s by running the following, which will print the nodes in the
K3s cluster and the number of available GPUs on the node:

```bash
$ kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
NAME   GPU
r3x    1
```

You may optionally also wish to configure the NVIDIA container runtime to be the default container. To do this, we need
to modify the K3s service definition to add an additional argument. Add `--default-runtime nvidia` to `ExecStart` in
`/etc/systemd/system/k3s.service`:

```service
...
ExecStart=/usr/local/bin/k3s \
   server --default-runtime nvidia \
```
