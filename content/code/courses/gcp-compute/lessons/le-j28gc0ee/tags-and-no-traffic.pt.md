---
title: Tags e publicar sem tráfego
version: 1
---

Uma porcentagem manda usuários reais para uma revisão. Muitas vezes você quer o contrário primeiro:
**a revisão nova rodando, alcançável por você e pelos seus testes, e por mais ninguém.** O Cloud
Run faz isso com dois recursos que em geral andam juntos, uma publicação que não recebe tráfego e
uma tag que dá à revisão um endereço próprio.

## Publicando sem tráfego

Por padrão uma publicação move a parte do `LATEST` para a revisão nova, o que, com a divisão
padrão, é tudo. A opção que impede isso está documentada na ajuda do gcloud, que este laboratório
consegue ler:

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A9 -- '^     --no-traffic'
     --no-traffic
        True to avoid sending traffic to the revision being deployed. Setting
        this flag assigns any traffic assigned to the LATEST revision to the
        specific revision bound to LATEST before the deployment. The effect is
        that the revision being deployed will not receive traffic.

        After a deployment with this flag the LATEST revision will not receive
        traffic on future deployments. To restore sending traffic to the LATEST
        revision by default, run the gcloud run services update-traffic command
        with --to-latest.
```

**O `--no-traffic` congela a divisão como estava**: a parte que o `LATEST` tinha fica presa à
revisão que era a mais nova antes da publicação, então a revisão nova não recebe nada do tráfego do
serviço. O segundo parágrafo da ajuda é a parte que as pessoas perdem. Depois de uma publicação com
essa opção, **as publicações seguintes também não recebem tráfego**, porque nada mais aponta para o
`LATEST`, até alguém rodar `update-traffic --to-latest`. Uma equipe que usou a opção uma vez numa
liberação cuidadosa e esqueceu pode publicar uma correção várias vezes e se perguntar por que
ninguém a vê.

## Uma tag é um endereço

Uma **tag** é um nome preso a uma revisão na lista de tráfego, com `percent = 0` se ela não deve
levar parte nenhuma. A tag `canary` do `main.tf` da seção anterior é uma. O Cloud Run dá a toda tag
um endereço próprio, formado pondo a tag na frente do endereço do serviço com três hífens: para um
serviço em `https://orders-….run.app`, a tag responde em `https://canary---orders-….run.app`. Os
pontos estão no lugar da parte do endereço que o Google gera, que este laboratório não consegue
mostrar e não inventa.

```
ana@laptop:~/gcp$ gcloud run deploy --help | grep -A2 -- '^     --tag=TAG'
     --tag=TAG
        Traffic tag to assign to the newly created revision.
```

**Uma requisição ao endereço da tag sempre chega àquela revisão**, diga a divisão o que disser.
Então a sequência comum é: publicar com `--no-traffic --tag=canary`, rodar os testes e algumas
requisições à mão contra o endereço da tag, e só então dar uma porcentagem à revisão. A tag continua
útil depois: enquanto o canário leva 10%, o endereço dele ainda deixa você compará-lo com a revisão
estável requisição por requisição.

## Quem alcança uma tag

O endereço de uma tag é tão público quanto o do serviço. Se o serviço aceita requisições sem
autenticação, qualquer um que adivinhe ou descubra o endereço da tag pode usar a revisão inacabada,
e nomes como `canary`, `test` ou `next` são fáceis de adivinhar. Dois hábitos deixam isso pequeno.
**Tire a tag quando a liberação terminar**, para o endereço deixar de existir. E para um serviço que
não pode ser público, exija autenticação no serviço, o que vale para as tags dele também; a lição 12
trata do lado de rede.
