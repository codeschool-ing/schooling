---
title: Uma liberação gradual, e o caminho de volta
version: 1
---

Dividir tráfego é um mecanismo. **Uma liberação gradual é um procedimento construído sobre ele:
mover uma parte pequena para a revisão nova, observar algo que mostraria um problema, e mover mais
ou mover tudo de volta.** O mecanismo é o mesmo comando toda vez; o que torna uma liberação segura é
decidir antes o que você observa e o que faz você parar.

## Os comandos

A ajuda do gcloud lista os movimentos como exemplos, e eles são o vocabulário inteiro:

```
ana@laptop:~/gcp$ gcloud run services update-traffic --help | sed -n '/^EXAMPLES/,/^POSITIONAL/p'
EXAMPLES
    To assign 10% of traffic to revision myservice-s5sxn and 90% of traffic to
    revision myservice-cp9kw run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-s5sxn=10,myservice-cp9kw=90

    To increase the traffic to revision myservice-s5sxn to 20% and by reducing
    the traffic to revision myservice-cp9kw to 80% run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-s5sxn=20

    To rollback to revision myservice-cp9kw run:

        $ gcloud run services update-traffic myservice \
          --to-revisions=myservice-cp9kw=100

    To assign 100% of traffic to the current or future LATEST revision run:

        $ gcloud run services update-traffic myservice --to-latest

    You can also refer to the current or future LATEST revision in
    --to-revisions by the string "LATEST". For example, to set 10% of traffic
    to always float to the latest revision:

        $ gcloud run services update-traffic myservice \
          --to-revisions=LATEST=10

POSITIONAL ARGUMENTS
```

Leia como uma sequência. **10% para a revisão nova; depois 20%; depois, se der errado, 100% de volta
para a antiga**, que é voltar atrás num comando só e, como a seção 02 explicou, publicação nenhuma.
O `--to-latest` é o último passo de uma liberação que deu certo: tudo para a revisão mais nova, e as
publicações futuras também.

## O que observar, e por quanto tempo

A `orders-v2` da seção 02 respondia em cerca de um quarto de segundo onde a `orders-v1` levava
poucos milissegundos, no laptop. No Cloud Run essa diferença apareceria nas métricas de latência do
serviço, separadas por revisão, que o Cloud Monitoring coleta sem código nenhum; o `gcp-operations`
trata dos painéis e alertas. A regra de decisão é escrita antes de a liberação começar, por exemplo:
**se o percentil 95 da `orders-v2` ficar mais de 20% acima do da `orders-v1`, ou a taxa de erro
dela passar de 1%, mova tudo de volta.**

Quanto tempo observar depende de quanto tráfego a parte recebe, porque uma porcentagem de muito
pouco é muito pouco. O serviço de pedidos da loja recebe umas 2.000 requisições por hora à tarde.
Com 10%, a `orders-v2` vê umas 200 por hora, o bastante para ver a latência dobrar em minutos e
pouco demais para ver um erro que acontece uma vez em mil. Um erro raro precisa de mais tempo ou de
uma parte maior, e a conta diz qual: para esperar dez ocorrências de um erro de um em mil com 10% de
2.000 por hora são cinquenta horas, com 50% são dez.

## Fazendo à mão, e não fazendo à mão

Uma liberação tocada por alguém digitando `update-traffic` a cada hora funciona, e é como a maioria
das equipes começa. Ela falha de um jeito previsível: a pessoa fica ocupada, uma etapa dura um dia
em vez de uma hora, ou a verificação é pulada porque as últimas dez deram certo. **O Google Cloud
Deploy automatiza exatamente esse procedimento para o Cloud Run**, com etapas declaradas de antemão
e o tráfego movido pelo pipeline, e o `gcp-operations` volta a ele. O que ele automatiza é o
procedimento acima; ele não decide o que observar, e isso continua sendo seu para escrever.

## O caminho de volta, ensaiado

Voltar atrás só é rápido se já foi feito antes de alguém precisar. Duas coisas o mantêm rápido: **a
revisão antiga precisa existir**, então ela não é apagada enquanto uma mais nova está em
observação; e **a configuração dela precisa continuar funcionando**, então uma revisão que dependia
de uma coluna do banco que o código novo removeu não é uma revisão para onde se possa voltar. Essa
segunda não tem nada a ver com o Cloud Run, e é o motivo comum de uma volta atrás falhar: o código
voltou e os dados não.
