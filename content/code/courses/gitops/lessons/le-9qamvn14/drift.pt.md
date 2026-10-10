---
title: Desvio, e o que uma dúzia de linhas não faz
version: 1
---

**Desvio (drift) é uma diferença entre o cluster e a descrição que ninguém commitou.** Alguém escala
um deployment à mão durante um incidente, edita um valor para testar algo, ou apaga um objeto por
engano. Num arranjo de push essa diferença vive até o próximo deploy por acaso sobrescrevê-la. Um
reconciliador a encontra na próxima passada.

## Desvio, corrigido

Com o laço ainda rodando no segundo terminal, mude o cluster diretamente, como faria alguém com
pressa:

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   2/5     5            2           24s
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   2/2     2            2           41s
```

E no segundo terminal:

```
01:33:10 at 1949f7b
deployment.apps/bulletin configured
```

A escala para cinco durou até a passada seguinte, quinze segundos no máximo, e então
`deployment.apps/bulletin configured` a pôs de volta nas duas que o arquivo pede. **O laço não sabia
que nada tinha acontecido.** Ele nunca compara, nunca observa eventos; ele aplica a descrição de novo,
e aplicar é idempotente, então o único efeito visível é no campo que tinha mudado.

Isso tem uma consequência que surpreende na primeira vez. Uma mudança de emergência feita com
`kubectl` durante um incidente é desfeita dentro de um intervalo. Num arranjo GitOps **o jeito de
mudar a produção depressa é um commit rápido**, e a aula 2 é sobre deixar esse caminho curto o
bastante para usar sob pressão.

## O que ele não faz

Três coisas dão errado com o laço, e cada uma é um recurso das ferramentas de verdade.

**Ele nunca apaga.** Tire o Service do `staging/bulletin.yaml`, faça commit e push:

```
ana@laptop:~/fleet$ git diff --stat
 staging/bulletin.yaml | 14 --------------
 1 file changed, 14 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -am "staging: no service"
ana@laptop:~/fleet$ git push --quiet
ana@laptop:~/fleet$ kubectl -n staging get service
NAME       TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
bulletin   NodePort   10.96.95.6   <none>        80:30080/TCP   58s
```

E o laço, na passada seguinte:

```
01:33:26 at a10aba9
```

Ele aplicou o que sobrou e não disse nada, e o service continua lá, porque o `kubectl apply -f` só
conhece os objetos dos arquivos que recebe. Um objeto tirado do Git vira um órfão que ninguém
possui. O Argo CD e o Flux guardam um registro do que aplicaram, então conseguem apagar o que sumiu;
isso se chama **pruning** (poda), e a aula 3 o liga.

**Ele não consegue dizer nada a você.** O cluster está sincronizado agora? Qual commit está rodando?
O último apply falhou? A resposta do laço é uma linha de saída num terminal de uma máquina. As
ferramentas de verdade guardam esse estado como objetos do Kubernetes que qualquer pessoa com acesso
consulta, e isso é boa parte do que as aulas 3 e 4 mostram.

**Ele tem as chaves do cluster inteiro.** O laço usa o seu kubeconfig, que pode tudo. A aula 11 é
sobre dar ao reconciliador só as permissões de que o trabalho dele precisa.

Ponha o Service de volta com `git revert --no-edit HEAD` e `git push`, e pare o laço com `Ctrl+C`; a
próxima aula troca o repositório bare por um servidor Git de verdade, e a aula 3 troca o laço.
