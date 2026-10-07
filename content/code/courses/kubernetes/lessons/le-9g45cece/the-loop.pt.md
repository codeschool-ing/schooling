---
title: Noventa linhas que fecham o ciclo
version: 1
---

**Um controller compara o que se quer com o que existe e muda o que existe**, de novo e de novo. O ciclo
nunca pergunta o que aconteceu; só pergunta como as coisas estão agora e como deveriam estar. Isso se
chama reconciliar, e é por isso que um controller pode ser parado, reiniciado ou perder um evento, e
ainda assim terminar certo: a próxima volta olha o estado inteiro de novo.

O controller de Backups da loja mantém um CronJob para cada Backup. Leia por partes:

```schooling-example
{"language": "go", "file": "main.go", "parts": [{"code": "// backup-controller keeps one CronJob for every Backup object in the\n// default namespace, and nothing else.\npackage main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\t\"log\"\n\t\"os\"\n\t\"time\"\n\n\tbatchv1 \"k8s.io/api/batch/v1\"\n\tcorev1 \"k8s.io/api/core/v1\"\n\tapierrors \"k8s.io/apimachinery/pkg/api/errors\"\n\tmetav1 \"k8s.io/apimachinery/pkg/apis/meta/v1\"\n\t\"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured\"\n\t\"k8s.io/apimachinery/pkg/runtime/schema\"\n\t\"k8s.io/client-go/dynamic\"\n\t\"k8s.io/client-go/kubernetes\"\n\t\"k8s.io/client-go/tools/clientcmd\"\n)\n\nvar backups = schema.GroupVersionResource{Group: \"shop.example.test\", Version: \"v1\", Resource: \"backups\"}\n\n", "note": "O client-go é a biblioteca que todo controller em Go usa, a mesma sobre a qual o kubectl é feito. `backups` nomeia o recurso novo por grupo, versão e plural, porque a biblioteca não tem tipo Go para ele."}, {"code": "func main() {\n\tcfg, err := clientcmd.BuildConfigFromFlags(\"\", os.Getenv(\"KUBECONFIG\"))\n\tif err != nil {\n\t\tlog.Fatal(err)\n\t}\n\tdyn := dynamic.NewForConfigOrDie(cfg)\n\tkube := kubernetes.NewForConfigOrDie(cfg)\n\tctx := context.Background()\n", "note": "**Ele se autentica exatamente como o kubectl**, pelo kubeconfig. Rodando no cluster, usaria o token da ServiceAccount do seu pod, o da lição 23."}, {"code": "\tfor {\n\t\tlist, err := dyn.Resource(backups).Namespace(\"default\").List(ctx, metav1.ListOptions{})\n\t\tif err != nil {\n\t\t\tlog.Print(err)\n\t\t} else {\n\t\t\tfor _, b := range list.Items {\n\t\t\t\tif err := reconcile(ctx, kube, b); err != nil {\n\t\t\t\t\tlog.Printf(\"%s: %v\", b.GetName(), err)\n\t\t\t\t}\n\t\t\t}\n\t\t}\n\t\ttime.Sleep(5 * time.Second)\n\t}\n}\n", "note": "**O ciclo.** Listar todo Backup, reconciliar cada um, esperar cinco segundos, de novo. Erros são registrados e o ciclo segue: a próxima volta é a nova tentativa."}, {"code": "\n// reconcile makes the CronJob for one Backup match what the Backup asks for.\nfunc reconcile(ctx context.Context, kube *kubernetes.Clientset, b unstructured.Unstructured) error {\n\tdatabase, _, _ := unstructured.NestedString(b.Object, \"spec\", \"database\")\n\tschedule, _, _ := unstructured.NestedString(b.Object, \"spec\", \"schedule\")\n\tkeep, _, _ := unstructured.NestedInt64(b.Object, \"spec\", \"keep\")\n", "note": "Ler o que se quer, do spec do Backup."}, {"code": "\twant := &batchv1.CronJob{\n\t\tObjectMeta: metav1.ObjectMeta{\n\t\t\tName: \"backup-\" + b.GetName(),\n\t\t\tOwnerReferences: []metav1.OwnerReference{{\n\t\t\t\tAPIVersion: \"shop.example.test/v1\", Kind: \"Backup\",\n\t\t\t\tName: b.GetName(), UID: b.GetUID(), Controller: ptr(true),\n\t\t\t}},\n\t\t},\n\t\tSpec: batchv1.CronJobSpec{\n\t\t\tSchedule: schedule,\n\t\t\tJobTemplate: batchv1.JobTemplateSpec{Spec: batchv1.JobSpec{Template: corev1.PodTemplateSpec{\n\t\t\t\tSpec: corev1.PodSpec{\n\t\t\t\t\tRestartPolicy: corev1.RestartPolicyNever,\n\t\t\t\t\tContainers: []corev1.Container{{\n\t\t\t\t\t\tName: \"dump\", Image: \"busybox:1.37\",\n\t\t\t\t\t\tCommand: []string{\"echo\", fmt.Sprintf(\"would dump %s and keep %d copies\", database, keep)},\n\t\t\t\t\t}},\n\t\t\t\t},\n\t\t\t}}},\n\t\t},\n\t}\n", "note": "**Montar o CronJob que deveria existir.** A referência de dono torna o Backup o dono dele, então apagar o Backup apaga o CronJob sem código nenhum aqui. O Job só imprime o que um de verdade faria."}, {"code": "\tcronjobs := kube.BatchV1().CronJobs(\"default\")\n\thave, err := cronjobs.Get(ctx, want.Name, metav1.GetOptions{})\n\tswitch {\n\tcase apierrors.IsNotFound(err):\n\t\t_, err = cronjobs.Create(ctx, want, metav1.CreateOptions{})\n\t\tif err == nil {\n\t\t\tlog.Printf(\"%s: created cronjob %s (%s)\", b.GetName(), want.Name, schedule)\n\t\t}\n\t\treturn err\n\tcase err != nil:\n\t\treturn err\n\tcase have.Spec.Schedule != schedule:\n\t\tlog.Printf(\"%s: schedule %q -> %q\", b.GetName(), have.Spec.Schedule, schedule)\n\t\thave.Spec = want.Spec\n\t\t_, err = cronjobs.Update(ctx, have, metav1.UpdateOptions{})\n\t\treturn err\n\t}\n\treturn nil\n}\n", "note": "**Comparar e agir.** Faltando: criar. Horário diferente: atualizar. Igual: não fazer nada. Não fazer nada quando nada difere é o que torna seguro rodar o ciclo para sempre."}, {"code": "\nfunc ptr[T any](v T) *T { return &v }\n"}]}
```

Ele roda na sua máquina, ao lado do `kubectl` e com o mesmo kubeconfig. Depois do `./up.sh`, o tipo
Backup volta a partir do `backup-crd.yaml` da aula 43, e o `main.go` vai para um diretório só dele,
`~/shop/backup-controller`. Ele precisa do client-go v0.37.1, que precisa do Go 1.26, e como na aula 1
um container que tem Go o compila, então nada é instalado. A última linha inicia o controller; rode-a
num segundo terminal, onde ele continua até o `Ctrl+C`, e o log dele vai para `controller.log`:

```sh
kubectl apply -f backup-crd.yaml
mkdir -p ~/shop/backup-controller && cd ~/shop/backup-controller
docker run --rm -u $(id -u):$(id -g) -v "$PWD":/src -w /src -e GOCACHE=/tmp/cache -e GOPATH=/tmp/go golang:1.26 sh -c 'go mod init backup-controller && go get k8s.io/client-go@v0.37.1 && go mod tidy && CGO_ENABLED=0 go build -o backup-controller .'
KUBECONFIG=$HOME/.kube/config ./backup-controller > controller.log 2>&1
```

O `KUBECONFIG` precisa ser dito em voz alta, porque o programa lê essa variável e nada mais: sem ela, o
client-go procura as credenciais que um pod teria, não encontra nenhuma, e para.

**Este controller consulta em intervalos**: ele lista todo Backup a cada cinco segundos. Isso o mantém
curto o bastante para ser lido de uma vez, e é o formato errado para um cluster grande, onde mil objetos
listados a cada poucos segundos são carga no API server sem motivo. Controllers de verdade usam
informers: uma listagem no início, depois um watch que transmite cada mudança, um cache local que
responde às leituras, e uma fila de chaves para reconciliar. A biblioteca controller-runtime, para a
qual o Kubebuilder e o Operator SDK geram código, empacota tudo isso. A função de reconciliação,
comparar o desejado com o real, é a mesma de qualquer jeito.
