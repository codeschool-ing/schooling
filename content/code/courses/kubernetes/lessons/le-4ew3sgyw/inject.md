---
title: Variables and files from one object
version: 1
---

**Configuration baked into an image means a rebuild for every environment and every change of
mind**, and an image that differs between test and production is an image that was never tested.
A ConfigMap takes the configuration out: the image stays the same everywhere, and each cluster holds
its own ConfigMap beside it.

Two ConfigMaps, made two ways. Values typed on the command line become keys:

```
ana@laptop:~/shop$ kubectl create configmap shop-config --from-literal=GREETING="Ana's shop" --from-literal=CURRENCY=BRL
configmap/shop-config created
```

A file becomes one key whose value is the whole file:

```
Welcome back. Orders placed before 18:00 ship today.
```

```
ana@laptop:~/shop$ kubectl create configmap shop-files --from-file=greeting=greeting.txt
configmap/shop-files created
ana@laptop:~/shop$ kubectl get configmaps
NAME               DATA   AGE
kube-root-ca.crt   1      19s
shop-config        2      1s
shop-files         1      1s
ana@laptop:~/shop$ kubectl get configmap shop-config -o yaml | head -n 6
apiVersion: v1
data:
  CURRENCY: BRL
  GREETING: Ana's shop
kind: ConfigMap
metadata:
```

`DATA` counts the keys: two in `shop-config`, one in `shop-files`. The third ConfigMap,
`kube-root-ca.crt`, is put in every namespace by the cluster itself and holds the certificate pods use
to check they are talking to the real API server. Stored, a ConfigMap is just this: a `data` map of
strings, with no type and no structure beyond it.

## Into the pod

The Deployment reads them both ways:

```schooling-example
{"language": "yaml", "file": "shop.yaml", "parts": [{"code": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: shop\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: shop\n  template:\n    metadata:\n      labels:\n        app: shop\n    spec:\n      containers:\n      - name: shop\n        image: shop:1.0\n", "note": "**An ordinary Deployment of one copy**, with the same image as every lesson so far. Nothing in the image knows about the ConfigMaps."}, {"code": "        env:\n        - name: GREETING\n          valueFrom:\n            configMapKeyRef:\n              name: shop-config\n              key: GREETING\n", "note": "**One variable from one key.** `GREETING` in the container gets the value of the key `GREETING` in `shop-config`, read when the container starts."}, {"code": "        envFrom:\n        - prefix: SHOP_\n          configMapRef:\n            name: shop-config\n", "note": "**Every key at once**, each as a variable with `SHOP_` in front: `SHOP_GREETING` and `SHOP_CURRENCY`. The shop does not print them, so nothing below shows them."}, {"code": "        volumeMounts:\n        - name: files\n          mountPath: /etc/shop\n          readOnly: true\n", "note": "**Where the files appear** in the container: one file per key, under `/etc/shop`, read-only."}, {"code": "      volumes:\n      - name: files\n        configMap:\n          name: shop-files\n", "note": "**The volume is the ConfigMap.** Each key of `shop-files` becomes a file of that name, so `greeting` becomes `/etc/shop/greeting`."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: shop\nspec:\n  selector:\n    app: shop\n  ports:\n  - port: 80\n    targetPort: 8080\n", "note": "**A Service**, so the `probe` pod can ask `shop` by name."}]}
```

The `probe` pod asks the shop for its configuration:

```
ana@laptop:~/shop$ kubectl apply -f shop.yaml
deployment.apps/shop created
service/shop created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/config
GREETING=Ana's shop
/etc/shop/greeting: Welcome back. Orders placed before 18:00 ship today.
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/
Ana's shop 1.0 on shop-6fbfb8588d-vdprj
```

**The variable came from `shop-config` and the file from `shop-files`**, and the image knows about
neither: it reads an environment variable and a path, as it would on a laptop. The shop's front page
now greets as `Ana's shop`, the same image that said `shop` in every earlier lesson.

| | as an environment variable | as a file on a volume |
|---|---|---|
| written as | `env` with `configMapKeyRef`, or `envFrom` | a `configMap` volume and a `volumeMount` |
| read by the program | when it starts, like any variable | whenever it opens the file |
| suits | short values: a currency, a feature flag, a URL | whole files: a configuration file, a template, a certificate |
| a value that changes later | not seen by a running container | appears in the file, after a delay |

The last row is what the next section measures, because it is the difference that causes incidents.
A ConfigMap also has a size limit, one mebibyte, because it is stored in etcd with every other object;
anything bigger belongs in a volume of its own (lesson 26).
