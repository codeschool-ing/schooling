---
title: O pod que ainda recebe requisições
version: 1
---

Quando o controlador remove um pod antigo, duas coisas começam **no mesmo instante** e nada as ordena.
O kubelet manda `SIGTERM` ao container. O controlador de endpoints tira o pod do Service, e o kube-proxy
de cada nó então reescreve as regras. A segunda demora mais. Nesse meio-tempo, um nó ainda pode mandar
uma conexão nova a um processo que já parou de escutar.

A loja trata o `SIGTERM` com educação: para de aceitar conexões e termina as requisições que já tem. É
exatamente isso que torna a brecha visível. Uma conexão que chega depois desse ponto é **recusada**, e o
`wget` do BusyBox diz isso com essas palavras.

A correção de costume é fazer o pod esperar antes de ouvir o sinal. Um hook `preStop` roda primeiro, e o
`SIGTERM` só é enviado quando ele termina; a ação `sleep` não precisa de shell na imagem:

```yaml
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: shop
        lifecycle:
          preStop:
            sleep:
              seconds: 10
```

`terminationGracePeriodSeconds` é o orçamento inteiro, hook incluído. Depois de trinta segundos o
container é morto, faça o que estiver fazendo, então a espera tem de deixar tempo para o desligamento
depois dela. Depois, a mesma contagem, numa atualização para `2.0`:

```
ana@laptop:~/shop$ kubectl patch deployment shop --patch-file graceful.yaml
deployment.apps/shop patched
ana@laptop:~/shop$ kubectl exec probe -- sh -c "for i in \$(seq 300); do wget -qO- -T 2 shop || echo FAILED; sleep 0.1; done" | cut -d" " -f1,2 | sort | uniq -c
wget: download timed out
      1 FAILED
     28 shop 1.1
    271 shop 2.0
ana@laptop:~/shop$ kubectl set image deployment/shop shop=shop:2.0
deployment.apps/shop image updated
```

**Uma falha de novo, e de novo um timeout.** Leia o erro antes da contagem. Uma conexão recusada é a
corrida acima; um timeout é outra coisa, um pacote que não teve resposta nenhuma. Nenhuma das rodadas
teve uma recusa, então neste laboratório a corrida não apareceu, e o timeout que sobrou tem uma causa que
esta lição não encontrou. O `preStop` continua valendo, porque a corrida é real onde quer que o
kube-proxy seja mais lento que aqui. O que a contagem diz é mais estreito: ela não levou esta rodada a
zero.

Esse é o estado honesto da maioria dos rolling updates. Eles são **quase** de graça, e o cliente que não
pode perder uma única requisição a repete, já que um `GET` idempotente repetido uma vez não custa nada.
