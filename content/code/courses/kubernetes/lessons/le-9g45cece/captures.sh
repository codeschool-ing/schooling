#!/usr/bin/env bash
# The terminal sessions quoted in lesson 44 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the cluster, and the Backup CustomResourceDefinition of lesson 43,
#     applied again.
#   - building the controller with the docker command the lesson shows,
#     golang:1.26 and client-go v0.37.1.
#   - the controller runs on the laptop, in the background, with the same
#     kubeconfig kubectl uses; its log is a file the lesson reads, as a second
#     terminal would show it. The pauses let it make a pass (every five
#     seconds).
# Names, uids and times differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

PROXY=${HTTPS_PROXY:-}
. "$(dirname "$0")/../../capture.sh"
fresh
rm -rf /home/ana/shop/backup-controller
mkdir -p /home/ana/shop/backup-controller
cat >/tmp/backup-crd.yaml <<'CODE'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.shop.example.test
spec:
  group: shop.example.test
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: ["bk"]
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        required: ["spec"]
        properties:
          spec:
            type: object
            required: ["database", "schedule"]
            properties:
              database:
                type: string
              schedule:
                type: string
              keep:
                type: integer
                minimum: 1
                maximum: 30
                default: 7
          status:
            type: object
            properties:
              lastRun:
                type: string
    subresources:
      status: {}
    additionalPrinterColumns:
    - name: Database
      type: string
      jsonPath: .spec.database
    - name: Schedule
      type: string
      jsonPath: .spec.schedule
    - name: Keep
      type: integer
      jsonPath: .spec.keep
    - name: Last run
      type: string
      jsonPath: .status.lastRun
CODE
quiet 'kubectl apply -f /tmp/backup-crd.yaml'
quiet 'kubectl wait --for=condition=Established crd/backups.shop.example.test --timeout=60s'
cd /home/ana/shop/backup-controller

block source
put main.go <<'CODE'
// backup-controller keeps one CronJob for every Backup object in the
// default namespace, and nothing else.
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

var backups = schema.GroupVersionResource{Group: "shop.example.test", Version: "v1", Resource: "backups"}

func main() {
	cfg, err := clientcmd.BuildConfigFromFlags("", os.Getenv("KUBECONFIG"))
	if err != nil {
		log.Fatal(err)
	}
	dyn := dynamic.NewForConfigOrDie(cfg)
	kube := kubernetes.NewForConfigOrDie(cfg)
	ctx := context.Background()
	for {
		list, err := dyn.Resource(backups).Namespace("default").List(ctx, metav1.ListOptions{})
		if err != nil {
			log.Print(err)
		} else {
			for _, b := range list.Items {
				if err := reconcile(ctx, kube, b); err != nil {
					log.Printf("%s: %v", b.GetName(), err)
				}
			}
		}
		time.Sleep(5 * time.Second)
	}
}

// reconcile makes the CronJob for one Backup match what the Backup asks for.
func reconcile(ctx context.Context, kube *kubernetes.Clientset, b unstructured.Unstructured) error {
	database, _, _ := unstructured.NestedString(b.Object, "spec", "database")
	schedule, _, _ := unstructured.NestedString(b.Object, "spec", "schedule")
	keep, _, _ := unstructured.NestedInt64(b.Object, "spec", "keep")
	want := &batchv1.CronJob{
		ObjectMeta: metav1.ObjectMeta{
			Name: "backup-" + b.GetName(),
			OwnerReferences: []metav1.OwnerReference{{
				APIVersion: "shop.example.test/v1", Kind: "Backup",
				Name: b.GetName(), UID: b.GetUID(), Controller: ptr(true),
			}},
		},
		Spec: batchv1.CronJobSpec{
			Schedule: schedule,
			JobTemplate: batchv1.JobTemplateSpec{Spec: batchv1.JobSpec{Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					RestartPolicy: corev1.RestartPolicyNever,
					Containers: []corev1.Container{{
						Name: "dump", Image: "busybox:1.37",
						Command: []string{"echo", fmt.Sprintf("would dump %s and keep %d copies", database, keep)},
					}},
				},
			}}},
		},
	}
	cronjobs := kube.BatchV1().CronJobs("default")
	have, err := cronjobs.Get(ctx, want.Name, metav1.GetOptions{})
	switch {
	case apierrors.IsNotFound(err):
		_, err = cronjobs.Create(ctx, want, metav1.CreateOptions{})
		if err == nil {
			log.Printf("%s: created cronjob %s (%s)", b.GetName(), want.Name, schedule)
		}
		return err
	case err != nil:
		return err
	case have.Spec.Schedule != schedule:
		log.Printf("%s: schedule %q -> %q", b.GetName(), have.Spec.Schedule, schedule)
		have.Spec = want.Spec
		_, err = cronjobs.Update(ctx, have, metav1.UpdateOptions{})
		return err
	}
	return nil
}

func ptr[T any](v T) *T { return &v }
CODE
# The build the lesson shows, plus the recording machine's CA, which the
# Go container needs to verify the module proxy through its TLS inspection.
rm -f go.mod go.sum
docker run --rm -u $(id -u):$(id -g) -v /root/.ccr/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro -v "$PWD":/src -w /src -e GOCACHE=/tmp/cache -e GOPATH=/tmp/go golang:1.26 sh -c 'go mod init backup-controller && go get k8s.io/client-go@v0.37.1 && go mod tidy && CGO_ENABLED=0 go build -o backup-controller .' >/dev/null 2>&1 || { echo "##### the controller did not build" >&2; exit 1; }
./backup-controller >controller.log 2>&1 & CTRL=$!
trap 'kill $CTRL 2>/dev/null' EXIT

block create
put nightly.yaml <<'CODE'
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: orders-nightly
spec:
  database: orders
  schedule: "0 3 * * *"
CODE
run 'kubectl apply -f nightly.yaml'
quiet 'sleep 7'
run 'cat controller.log'
run 'kubectl get cronjobs'
run 'kubectl get cronjob backup-orders-nightly -o jsonpath="{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}"; echo'
block run-it
run 'kubectl create job manual --from=cronjob/backup-orders-nightly'
quiet 'kubectl wait --for=condition=Complete job/manual --timeout=60s'
run 'kubectl logs job/manual'
block change
run "kubectl patch backup orders-nightly --type=merge -p '{\"spec\":{\"schedule\":\"30 2 * * *\"}}'"
quiet 'sleep 7'
run 'tail -n 1 controller.log'
run 'kubectl get cronjobs'
block heal
run 'kubectl delete cronjob backup-orders-nightly'
quiet 'sleep 7'
run 'tail -n 1 controller.log'
run 'kubectl get cronjobs'
block delete
run 'kubectl delete backup orders-nightly'
quiet 'sleep 5'
run 'kubectl get cronjobs,backups'
