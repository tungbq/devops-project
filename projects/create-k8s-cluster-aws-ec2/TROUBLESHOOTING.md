# URLs

- https://stackoverflow.com/questions/75704841/aws-pem-powershell-connection-works-wsl-returns-too-open-permissions
- https://www.schakko.de/2020/01/10/fixing-unprotected-key-file-when-using-ssh-or-ansible-inside-wsl/

# Checking master node

- https://devopscube.com/setup-kubernetes-cluster-kubeadm/

```
kubectl get po -n kube-system
kubectl get --raw='/readyz?verbose'
kubectl get nodes
kubeadm token create --print-join-command

# kubeadm join x.x.x.x:6443 --token abcxyz.blabla --discovery-token-ca-cert-hash sha256:blabla
kubectl get nodes

kubectl label node worker-node01  node-role.kubernetes.io/worker=worker

```
