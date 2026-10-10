---
title: Applications in Git, too
version: 1
---

**The Application lives in `~/setup` on your machine, applied by hand**, which is exactly the
situation this course has been removing for everything else. If your laptop disappears, nobody else
knows how staging is wired to the repository. The fix is the obvious one: put the Application in
`fleet` and let Argo CD apply it.

That needs one Application applied by hand, once, whose job is to apply the others. It is called
the **app of apps**, or the root. Save this as `~/setup/root.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea:3000/ana/fleet.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

It points at a directory `argocd/` in `fleet`, and every Application manifest in that directory is
one of its objects. Move the staging Application there, through a pull request, and apply the root:

```
ana@laptop:~/fleet$ git switch --quiet -c app-of-apps
ana@laptop:~/fleet$ mkdir argocd && cp ~/setup/bulletin-staging.yaml argocd/
ana@laptop:~/fleet$ git add argocd
ana@laptop:~/fleet$ git commit --quiet -m "argocd: the staging application lives in Git"
ana@laptop:~/fleet$ kubectl apply -f ~/setup/root.yaml
application.argoproj.io/root created
ana@laptop:~/fleet$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
argocd/root              https://kubernetes.default.svc  argocd     default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  argocd   main
```

Both are `Synced`. The root found `argocd/bulletin-staging.yaml` in Git, compared it with the
Application that already existed, and adopted it. From now on, **adding an application to the
cluster is a pull request that adds a file to `argocd/`**, and removing one is a pull request that
deletes it, with the prune of the last section doing the rest.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 260\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"The app of apps. A root Application, applied once by hand, points at the argocd directory in Git. That directory holds the bulletin-staging Application, which points at the staging directory, whose objects land in the staging namespace.\"><rect x=\"0\" y=\"0\" width=\"640\" height=\"260\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"105.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">root</text><text x=\"105.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">applied once, by hand</text><rect x=\"240\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">fleet/argocd/</text><text x=\"325.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Application files</text><rect x=\"240\" y=\"140\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"325.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">bulletin-staging</text><text x=\"325.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">an Application</text><rect x=\"460\" y=\"140\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"540.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">fleet/staging/</text><text x=\"540.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">manifests</text><rect x=\"460\" y=\"30\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"540.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">namespace staging</text><text x=\"540.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">the objects</text><line x1=\"190\" y1=\"55\" x2=\"228.0\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"236,55 228.0,50.5 228.0,59.5\" fill=\"var(--paper-dim)\"/><line x1=\"325\" y1=\"80\" x2=\"325.0\" y2=\"128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"325,136 329.5,128.0 320.5,128.0\" fill=\"var(--paper-dim)\"/><line x1=\"410\" y1=\"165\" x2=\"448.0\" y2=\"165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"456,165 448.0,160.5 448.0,169.5\" fill=\"var(--paper-dim)\"/><line x1=\"540\" y1=\"140\" x2=\"540.0\" y2=\"92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"540,84 535.5,92.0 544.5,92.0\" fill=\"var(--phosphor)\"/><text x=\"320\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">everything below the root is in Git</text></svg>", "caption": "One Application applied by hand, and everything else read from the repository. Adding or removing an application is a pull request to fleet/argocd/."}
```

The one thing left outside Git is `~/setup/root.yaml` and the Argo CD installation itself. That is the
bootstrap, and every GitOps setup has one: something has to exist before the agent can read the
repository. Keeping it to two files you can apply in a minute is the goal. Lesson 5 comes back to
this, with Flux, whose bootstrap commits itself into the repository.
