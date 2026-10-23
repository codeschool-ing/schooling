---
title: x
version: 1
---

Save it as `k8s/linkbox.yaml`:

```yaml
# linkbox in its own namespace, which Pod Security Admission holds to the
# restricted profile: a pod that could run as root, escalate or keep a
# capability is refused before it is scheduled.
apiVersion: v1
kind: Namespace
metadata:
  name: linkbox
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkbox
  namespace: linkbox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: linkbox
  template:
    metadata:
      labels:
        app: linkbox
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: linkbox
          image: localhost:5000/linkbox:main
          ports:
            - containerPort: 8000
          env:
            - name: LINKBOX_TOKEN
              valueFrom:
                secretKeyRef:
                  name: linkbox
                  key: token
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              memory: 128Mi
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: data
              mountPath: /data
      volumes:
        - name: tmp
          emptyDir: {}
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: linkbox
  namespace: linkbox
spec:
  selector:
    app: linkbox
  ports:
    - port: 80
      targetPort: 8000
```
