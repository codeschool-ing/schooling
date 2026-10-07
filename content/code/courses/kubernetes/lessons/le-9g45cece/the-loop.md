---
title: Ninety lines that close the loop
version: 1
---

**A controller compares what is wanted with what exists and changes what exists**, over and over. The
loop never asks what happened; it only asks how things are now and how they should be. That is called
reconciling, and it is why a controller can be stopped, restarted, or miss an event, and still end up
right: the next pass looks at the whole state again.

The shop's Backup controller keeps one CronJob for every Backup. Read it in parts:

```schooling-example
{"language": "go", "file": "main.go", "parts": [{"code": "// backup-controller keeps one CronJob for every Backup object in the\n// default namespace, and nothing else.\npackage main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\t\"log\"\n\t\"os\"\n\t\"time\"\n\n\tbatchv1 \"k8s.io/api/batch/v1\"\n\tcorev1 \"k8s.io/api/core/v1\"\n\tapierrors \"k8s.io/apimachinery/pkg/api/errors\"\n\tmetav1 \"k8s.io/apimachinery/pkg/apis/meta/v1\"\n\t\"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured\"\n\t\"k8s.io/apimachinery/pkg/runtime/schema\"\n\t\"k8s.io/client-go/dynamic\"\n\t\"k8s.io/client-go/kubernetes\"\n\t\"k8s.io/client-go/tools/clientcmd\"\n)\n\nvar backups = schema.GroupVersionResource{Group: \"shop.example.test\", Version: \"v1\", Resource: \"backups\"}\n\n", "note": "client-go is the library every Go controller uses, the same one kubectl is built on. `backups` names the new resource by group, version and plural, because the library has no Go type for it."}, {"code": "func main() {\n\tcfg, err := clientcmd.BuildConfigFromFlags(\"\", os.Getenv(\"KUBECONFIG\"))\n\tif err != nil {\n\t\tlog.Fatal(err)\n\t}\n\tdyn := dynamic.NewForConfigOrDie(cfg)\n\tkube := kubernetes.NewForConfigOrDie(cfg)\n\tctx := context.Background()\n", "note": "**It authenticates exactly as kubectl does**, from the kubeconfig. Run in the cluster, it would use its pod's ServiceAccount token instead, lesson 23's."}, {"code": "\tfor {\n\t\tlist, err := dyn.Resource(backups).Namespace(\"default\").List(ctx, metav1.ListOptions{})\n\t\tif err != nil {\n\t\t\tlog.Print(err)\n\t\t} else {\n\t\t\tfor _, b := range list.Items {\n\t\t\t\tif err := reconcile(ctx, kube, b); err != nil {\n\t\t\t\t\tlog.Printf(\"%s: %v\", b.GetName(), err)\n\t\t\t\t}\n\t\t\t}\n\t\t}\n\t\ttime.Sleep(5 * time.Second)\n\t}\n}\n", "note": "**The loop.** List every Backup, reconcile each one, wait five seconds, again. Errors are logged and the loop carries on: the next pass is the retry."}, {"code": "\n// reconcile makes the CronJob for one Backup match what the Backup asks for.\nfunc reconcile(ctx context.Context, kube *kubernetes.Clientset, b unstructured.Unstructured) error {\n\tdatabase, _, _ := unstructured.NestedString(b.Object, \"spec\", \"database\")\n\tschedule, _, _ := unstructured.NestedString(b.Object, \"spec\", \"schedule\")\n\tkeep, _, _ := unstructured.NestedInt64(b.Object, \"spec\", \"keep\")\n", "note": "Read what is wanted, from the Backup's spec."}, {"code": "\twant := &batchv1.CronJob{\n\t\tObjectMeta: metav1.ObjectMeta{\n\t\t\tName: \"backup-\" + b.GetName(),\n\t\t\tOwnerReferences: []metav1.OwnerReference{{\n\t\t\t\tAPIVersion: \"shop.example.test/v1\", Kind: \"Backup\",\n\t\t\t\tName: b.GetName(), UID: b.GetUID(), Controller: ptr(true),\n\t\t\t}},\n\t\t},\n\t\tSpec: batchv1.CronJobSpec{\n\t\t\tSchedule: schedule,\n\t\t\tJobTemplate: batchv1.JobTemplateSpec{Spec: batchv1.JobSpec{Template: corev1.PodTemplateSpec{\n\t\t\t\tSpec: corev1.PodSpec{\n\t\t\t\t\tRestartPolicy: corev1.RestartPolicyNever,\n\t\t\t\t\tContainers: []corev1.Container{{\n\t\t\t\t\t\tName: \"dump\", Image: \"busybox:1.37\",\n\t\t\t\t\t\tCommand: []string{\"echo\", fmt.Sprintf(\"would dump %s and keep %d copies\", database, keep)},\n\t\t\t\t\t}},\n\t\t\t\t},\n\t\t\t}}},\n\t\t},\n\t}\n", "note": "**Build the CronJob that should exist.** The owner reference makes the Backup its owner, so deleting the Backup deletes the CronJob with no code here. The Job only prints what a real one would do."}, {"code": "\tcronjobs := kube.BatchV1().CronJobs(\"default\")\n\thave, err := cronjobs.Get(ctx, want.Name, metav1.GetOptions{})\n\tswitch {\n\tcase apierrors.IsNotFound(err):\n\t\t_, err = cronjobs.Create(ctx, want, metav1.CreateOptions{})\n\t\tif err == nil {\n\t\t\tlog.Printf(\"%s: created cronjob %s (%s)\", b.GetName(), want.Name, schedule)\n\t\t}\n\t\treturn err\n\tcase err != nil:\n\t\treturn err\n\tcase have.Spec.Schedule != schedule:\n\t\tlog.Printf(\"%s: schedule %q -> %q\", b.GetName(), have.Spec.Schedule, schedule)\n\t\thave.Spec = want.Spec\n\t\t_, err = cronjobs.Update(ctx, have, metav1.UpdateOptions{})\n\t\treturn err\n\t}\n\treturn nil\n}\n", "note": "**Compare and act.** Missing: create it. Different schedule: update it. The same: do nothing. Doing nothing when nothing differs is what makes it safe to run the loop forever."}, {"code": "\nfunc ptr[T any](v T) *T { return &v }\n"}]}
```

It runs on your machine, beside `kubectl` and with the same kubeconfig. After `./up.sh`, the Backup
type goes back in from lesson 43's `backup-crd.yaml`, and `main.go` goes into a directory of its own,
`~/shop/backup-controller`. It needs client-go v0.37.1, which needs Go 1.26, and as in lesson 1 a
container that has Go builds it, so nothing is installed. The last line starts the controller; run it
in a second terminal, where it keeps going until `Ctrl+C`, and its log lands in `controller.log`:

```sh
kubectl apply -f backup-crd.yaml
mkdir -p ~/shop/backup-controller && cd ~/shop/backup-controller
docker run --rm -u $(id -u):$(id -g) -v "$PWD":/src -w /src -e GOCACHE=/tmp/cache -e GOPATH=/tmp/go golang:1.26 sh -c 'go mod init backup-controller && go get k8s.io/client-go@v0.37.1 && go mod tidy && CGO_ENABLED=0 go build -o backup-controller .'
KUBECONFIG=$HOME/.kube/config ./backup-controller > controller.log 2>&1
```

`KUBECONFIG` has to be said out loud, because the program reads that variable and nothing else: without
it, client-go looks for the credentials a pod would have, finds none, and stops.

**This controller polls**: it lists every Backup every five seconds. That keeps it short enough to read
in one sitting, and it is the wrong shape for a big cluster, where a thousand objects listed every few
seconds is load on the API server for no reason. Real controllers use informers: one list at start,
then a watch that streams every change, a local cache that answers reads, and a queue of keys to
reconcile. The controller-runtime library, which Kubebuilder and the Operator SDK generate code for,
packages all of that. The reconcile function, comparing wanted with actual, is the same either way.
