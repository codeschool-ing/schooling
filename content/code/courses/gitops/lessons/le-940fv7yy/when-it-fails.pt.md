---
title: Quando uma montagem falha
version: 1
---

O Kustomize e o Helm levam parte das falhas do cluster para a montagem: muitos erros agora aparecem
como um overlay ou um chart que não gera, antes de qualquer coisa ser aplicada. Nem todos. Cada caso
aqui foi produzido de propósito, numa cópia de trabalho jogada fora depois, e o primeiro é do tipo
que gera.

## Um patch sem nada para mudar

O patch do overlay de staging escolhe o alvo pelo tipo e pelo nome. Aqui o nome tem um erro de
digitação, então o patch não escolhe nada:

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -c nodePort
1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-    name: bulletin
+    name: bulletn
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -c nodePort
0
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | kubeconform -strict -summary -kubernetes-version 1.37.0
Summary: 4 resources found parsing stdin - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
```

**O Kustomize montou o overlay sem dizer nada.** Um patch cujo seletor não casa com nenhum objeto é
aplicado a nenhum objeto, e isso não é erro: o Service saiu com as portas da base e sem `nodePort`,
então o cluster escolheria uma porta qualquer e o `localhost:8080` pararia de responder. O
`kubeconform` também aprovou, porque um Service sem `nodePort` é um Service perfeitamente válido.

Nenhuma das duas checagens tem como saber que o patch deveria casar. Uma checagem que sabe é uma que
afirma algo sobre a saída: aqui, que o Service de staging tem a porta 30080. Uma linha no
`validate.sh` bastaria:

```sh
kubectl kustomize "$work/fleet/apps/bulletin/staging" | grep -q 'nodePort: 30080' || state=failure
```

Este curso não a acrescenta, porque cada afirmação dessas é mais uma coisa a manter verdadeira; mas a
lição é a geral. **Uma montagem que dá certo prova que os arquivos estão bem formados, não que dizem o
que você quis dizer.**

## Um valor que o chart exige

O chart diz que `image.tag` é obrigatório, e uma sobrescrita de valores o define como nada:

```
ana@laptop:~/fleet$ helm template preview charts/bulletin --set image.tag=null
Error: execution error at (bulletin/templates/deployment.yaml:17:50): image.tag is required

Use --debug flag to render out invalid YAML
```

O `required` transforma um valor ausente num erro com uma mensagem que alguém escreveu, em vez de um
Deployment com a imagem `localhost:5001/bulletin:`, que geraria, seria aplicado e falharia no cluster,
um pod de cada vez.
