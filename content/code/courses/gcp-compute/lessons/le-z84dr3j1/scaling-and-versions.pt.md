---
title: Classes de instância, escalonamento e versões
version: 1
---

Uma aplicação do App Engine não é um programa só. **É um conjunto de serviços, cada serviço um
conjunto de versões, e cada versão um conjunto de instâncias que o App Engine liga e desliga por
você.** A vitrine é o serviço `default`, que toda aplicação tem; um serviço `api` para os pedidos
poderia ficar ao lado, publicado e escalado por conta própria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Caixas aninhadas. O projeto planner-dev contém uma aplicação do App Engine, cuja região southamerica-east1 fica fixa quando ela é criada. A aplicação contém dois serviços, default e api. O serviço default contém duas versões: v1 recebe 90 por cento do tráfego e roda três instâncias; v2 recebe 10 por cento e roda uma instância. O serviço api contém uma versão, v7, com todo o tráfego dela e duas instâncias.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">projeto planner-dev</text><rect x=\"26\" y=\"42\" width=\"668\" height=\"226\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">aplicação, região southamerica-east1, fixa na criação</text><rect x=\"42\" y=\"76\" width=\"400\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">serviço default</text><rect x=\"54\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v1</text><text x=\"145\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">90% do tráfego</text><rect x=\"70\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"122\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"144\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"174\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"248\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"339\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v2</text><text x=\"339\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10% do tráfego</text><rect x=\"264\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"286\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"456\" y=\"76\" width=\"222\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">serviço api</text><rect x=\"476\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v7</text><text x=\"567\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo o tráfego dela</text><rect x=\"492\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"514\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"544\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"566\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text></svg>", "caption": "Uma aplicação por projeto e uma região por aplicação; dentro dela, serviços, versões e as instâncias que o App Engine sobe para cada versão.", "same": ["inst."]}
```
## Classes de instância e o preço delas

O ambiente padrão dimensiona instâncias por classe, não por vCPU e memória. Classes que começam com
**F** são para escalonamento automático, as que começam com **B** para escalonamento básico e
manual, e o número dobra o tamanho e o preço. A tabela da lição 1 traz as duas menores:

```
ana@laptop:~/gcp$ python3 prices.py other | grep 'App Engine'
  App Engine standard F1, after 28 free hours           0.05  per instance-hour
  App Engine standard B1, after 9 free hours            0.05  per instance-hour
  App Engine flexible vCPU                            0.0526  per vCPU-hour
  App Engine flexible memory                          0.0071  per GiB-hour
```

As duas custam 5 centavos por hora, e **as duas vêm com uma franquia gratuita todo dia**: 28
horas-instância de classes F e 9 de classes B por projeto, e é por isso que um site pequeno no App
Engine pode não custar nada por anos. Uma F2 custa 10 centavos e uma F4, 20, na mesma página.
Repare na unidade: hora-instância, contada por instância, por mais ocupada que ela estivesse.

## Três jeitos de escalar

| escalonamento | o que faz | as classes |
|---|---|---|
| **automático** | sobe instâncias pela taxa de requisições e pela latência, e pode ir a zero | F |
| **básico** | sobe uma instância quando chega uma requisição e a desliga depois de um tempo ociosa | B |
| **manual** | roda o número que você define, o tempo todo | B |

O automático é o padrão e é o que a vitrine usa. As configurações dele são as que se espera,
`min_instances`, `max_instances`, uma meta de uso de CPU, uma meta de requisições simultâneas, e a
documentação do Google diz como cada uma mexe na contagem. **O básico é o que as pessoas esquecem
que existe**: para uma ferramenta interna usada duas vezes por dia ele sobe uma instância na
primeira requisição e a solta depois, e as horas gratuitas das classes B muitas vezes cobrem tudo.

## Versões e tráfego

Todo deploy cria uma **versão**, com o nome que você der ou com a data. As versões convivem, e o
serviço manda tráfego para elas nas proporções que você define. **Este comando não foi executado**;
é como o Google documenta a divisão da vitrine entre duas versões:

```sh
gcloud app services set-traffic default --splits=v1=0.9,v2=0.1 --split-by=cookie
```

Noventa por cento dos visitantes recebem a `v1` e dez por cento a `v2`, e o `GAE_VERSION` na
página diz qual cada um recebeu. O `--split-by` decide como um visitante é atribuído: pelo
**endereço IP**, por um **cookie** que o App Engine grava, ou **aleatoriamente**. Um cookie mantém
uma pessoa numa versão entre requisições, o que importa no momento em que as duas versões
discordam sobre qualquer coisa que uma pessoa consiga ver.

Cada versão também tem o próprio endereço, `https://v2-dot-planner-dev.rj.r.appspot.com`, então
uma versão nova pode ser testada na própria URL sem tráfego nenhum antes de a divisão mudar. A
lição 9 faz o mesmo no Cloud Run com revisões e tags; as ideias são as mesmas, e as do Cloud Run são
as que o Google ainda está ampliando.
