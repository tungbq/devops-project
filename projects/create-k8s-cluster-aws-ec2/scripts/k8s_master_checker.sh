#!/bin/bash

kubectl get po -n kube-system
kubectl get --raw='/readyz?verbose'
kubectl get nodes
