---
title: Criando Backups, e o que o API server confere
version: 1
---

Um Backup se escreve como qualquer manifesto, com o grupo e o tipo novos:

```yaml
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: orders-nightly
spec:
  database: orders
  schedule: "0 3 * * *"
```

```
ana@laptop:~/shop$ kubectl apply -f nightly.yaml
backup.shop.example.test/orders-nightly created
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      
ana@laptop:~/shop$ kubectl get bk orders-nightly -o jsonpath="{.spec}"; echo
{"database":"orders","keep":7,"schedule":"0 3 * * *"}
```

As colunas da definição tornam o `kubectl get` útil, e `KEEP` diz 7 embora o manifesto nunca o tenha
mencionado: **o padrão do schema foi escrito no objeto quando ele foi guardado**, como a visão
`-o jsonpath` do spec confirma.

## Recusado na porta

O schema é aplicado pelo API server em toda escrita, antes de qualquer coisa ser guardada:

```yaml
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: forever
spec:
  database: orders
  schedule: "0 3 * * *"
  keep: 365
  compress: true
```

```
ana@laptop:~/shop$ kubectl apply -f bad.yaml
Error from server (BadRequest): error when creating "bad.yaml": Backup in version "v1" cannot be handled as a Backup: strict decoding error: unknown field "spec.compress"
ana@laptop:~/shop$ sed '/compress/d' bad.yaml | kubectl apply -f -
The Backup "forever" is invalid: spec.keep: Invalid value: 365: spec.keep in body should be less than or equal to 30
```

Dois problemas, e duas recusas. A primeira tentativa cita o campo desconhecido, `compress`: o kubectl
pede ao servidor validação estrita, então um campo que o schema não lista é um erro em vez de ser
descartado em silêncio. Com essa linha removida, a segunda tentativa cita o problema seguinte, `keep`
acima do máximo de 30. **Um erro de digitação num nome de campo é o engano mais comum em qualquer
manifesto**, e um schema é o que o transforma de uma configuração que não faz nada, em silêncio, num
erro com uma linha para corrigir.

## Spec e status

`spec` é o que uma pessoa quer; `status` é o que um programa informa. Com o sub-recurso de status
ligado, os dois são escritos por rotas diferentes:

```
ana@laptop:~/shop$ kubectl patch backup orders-nightly --subresource=status --type=merge -p '{"status":{"lastRun":"2026-10-06T03:00:00Z"}}'
backup.shop.example.test/orders-nightly patched
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      2026-10-06T03:00:00Z
ana@laptop:~/shop$ kubectl patch backup orders-nightly --type=merge -p '{"status":{"lastRun":"never"}}'
backup.shop.example.test/orders-nightly patched (no change)
ana@laptop:~/shop$ kubectl get backups
NAME             DATABASE   SCHEDULE    KEEP   LAST RUN
orders-nightly   orders     0 3 * * *   7      2026-10-06T03:00:00Z
```

O primeiro patch passou por `--subresource=status` e a coluna `LAST RUN` foi preenchida. O segundo
tentou definir `status` pela rota principal e foi ignorado: `(no change)`. Essa separação é o que deixa
o RBAC dar a um controller o direito de informar status sem o direito de mudar o que as pessoas
pediram, e às pessoas o contrário.

## O que uma CRD não faz

```
ana@laptop:~/shop$ kubectl get jobs,cronjobs
No resources found in default namespace.
ana@laptop:~/shop$ kubectl get --raw /apis/shop.example.test/v1/namespaces/default/backups/orders-nightly | head -c 160; echo
{"apiVersion":"shop.example.test/v1","kind":"Backup","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"shop.examp
```

**Nenhum Job, nenhum CronJob, nada.** O Backup diz que um backup deve rodar toda noite às três, e o
cluster guardou essa frase e a devolve a quem perguntar. Nada a lê. Uma CRD acrescenta um substantivo à
API; o verbo, o programa que observa Backups e faz os backups acontecerem, é um controller, e escrever
um é a lição 44.
