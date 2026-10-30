---
title: O que a mudança custa, e nenhuma tabela de preços mostra
version: 1
---

A coluna mais barata da seção anterior é um preço para rodar a carga depois que ela está lá.
**Levá-la até lá é uma segunda conta, paga em horas de engenharia**, e muitas vezes é maior que um
ano da diferença. Um serviço que economiza 20 USD por mês indo para o Functions e precisa de seis
semanas de retrabalho para chegar lá comprou a economia a um preço que ninguém assinaria por escrito.

O que torna uma mudança cara quase nunca é o código que responde a uma requisição. É o que o código
supõe, em silêncio, sobre o lugar onde roda. A API da loja é o exemplo do começo ao fim, porque já
supõe duas destas coisas.

## Cinco suposições que não viajam

**Um disco só seu.** Um programa numa máquina virtual grava uploads, caches e relatórios no próprio
sistema de arquivos e os encontra lá amanhã. O sistema de arquivos de um contêiner dura o tempo que
o contêiner dura, e uma réplica, uma instância de função ou um pod podem ser trocados a qualquer
momento pela plataforma que os colocou ali. Sair da máquina quer dizer achar cada gravação e mandá-la
antes para algum lugar que sobreviva ao processo: o compartilhamento do Azure Files da lição 3,
montado como a lição 7 o montou para o relatório, ou o Blob Storage, ou um banco de dados.

**Memória que sobrevive a uma requisição.** Sessões guardadas no processo, um cache em memória, um
contador. A loja tem uma: o `app.py` guarda os pedidos numa lista Python, `ORDERS`. Duas cópias da
imagem mostram o que isso significa, cada uma numa porta própria. Um pedido vai para a primeira, e
as duas são consultadas:

```
ana@laptop:~/azure$ docker run -d --name shop-a -p 8081:8080 shop:1.0
c3b13233255e5254a508907791db20e568fef0bc80d7a432c060c994e4ca0ea4
ana@laptop:~/azure$ docker run -d --name shop-b -p 8082:8080 shop:1.0
d5e48f2b82a9240fcaf86eaf421cdb0457f749e8d3aaa330422b810645913d04
ana@laptop:~/azure$ curl -s -X POST localhost:8081/orders -d '{"item": "coffee", "qty": 2}'; echo
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s localhost:8081/orders; echo
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s localhost:8082/orders; echo
[]
ana@laptop:~/azure$ docker restart shop-a
shop-a
ana@laptop:~/azure$ curl -s localhost:8081/orders; echo
[]
```

As strings compridas são ids de contêiner, diferentes a cada execução. **A segunda cópia nunca ouviu
falar do pedido, e a primeira o esqueceu quando reiniciou.** Numa máquina só, isso era um bug
esperando um reinício. Em duas réplicas atrás do ingress do Container Apps, ou em duas instâncias de
um plano do App Service, todo outro cliente veria uma lista vazia, e no Functions não existe processo
onde guardar a lista. Os pedidos têm de ir para um armazenamento compartilhado, um banco de dados,
antes que o código possa ir para qualquer lugar com dois de alguma coisa, e isso inclui o par de
máquinas virtuais.

**Um processo que roda por muito tempo.** Uma função para no timeout. No Flex Consumption o padrão é
de 30 minutos e nenhum máximo é imposto, mas a lição 16 leu as letras miúdas: uma execução ganha 60
minutos de tolerância quando a instância dela é retirada durante a redução de escala. Um job do
Container Apps tem o `replicaTimeout` da lição 8, um prazo que você escolhe. Uma máquina virtual roda
um job pelo tempo que o job quiser, que é a única coisa que ela faz e nada mais aqui faz por padrão.

**Uma requisição que espera muito tempo.** É o limite que pega as pessoas, porque não é o timeout que
elas configuraram. **Uma função HTTP tem 230 segundos para responder**, em todo plano, diga o timeout
o que disser; a documentação do Functions dá como motivo o tempo ocioso padrão do Azure Load
Balancer, e aponta para o FAQ do próprio App Service a respeito, então conte com os mesmos 230
segundos num web app. A documentação do ingress do Container Apps dá um timeout de requisição de 240
segundos. Um endpoint que gera um arquivo de cinco minutos enquanto o navegador espera não funciona
em nenhum dos dois. Ele tem de virar um job: aceitar o pedido, pô-lo numa fila (lição 20), e deixar
o cliente buscar o resultado depois. No Functions, o Durable Functions (lição 17) é o jeito de rodar
trabalho que dura mais que uma requisição.

**Uma conexão que fica aberta.** Um pool de 20 conexões ao banco por processo dá 40 para duas
máquinas ou duas réplicas, o que o banco espera. No Flex Consumption, um app Python aceita uma
requisição HTTP por instância de cada vez, então cada requisição em andamento é uma instância, cada
uma com o próprio pool. O pico da noite da loja, 80 por segundo a 100 ms, são oito instâncias; uma
rajada até o máximo padrão do app, as 100 instâncias da lição 16, são 100 pools, e o banco é a
primeira coisa a cair.

## O que cada opção pede do código

As mesmas suposições dão um custo aproximado para cada destino, antes de ler uma linha do código:

| destino | o que o código tem de virar |
| --- | --- |
| duas máquinas virtuais | nada de novo: o processo roda como hoje, e você assume o sistema operacional, os patches dele e manter as duas iguais (lição 4) |
| Container Apps | uma imagem de contêiner que escuta numa porta, o que a `shop:1.0` da lição 7 já é; nenhum estado na memória ou no disco local; configuração em variáveis de ambiente |
| App Service | a mesma imagem, com a porta no app setting `WEBSITES_PORT` (lição 18), ou o código publicado como arquivos; a mesma ausência de estado quando o plano tiver duas instâncias |
| Functions | uma assinatura de função: o servidor web trocado por handlers no `function_app.py` (lição 15), toda resposta HTTP dentro de 230 segundos, uma requisição por instância a não ser que você aumente |
| AKS | a imagem, mais os manifests que a rodam: um Deployment, um Service e uma rota (lições 11 e 14), num cluster que alguém atualiza |

**Mudanças em direção ao Functions custam mais**, porque uma função é o que menos supõe sobre onde
roda. O `app.py` da loja é um servidor web com o próprio roteamento, e no Functions o servidor é o do
host: cada rota vira um handler com um decorator, e o processo em volta deles vai embora. O que isso
compra é o ponto da lição 15. Onde o código é quase todo entrada e saída, uma fila lida aqui e um
blob gravado ali, um binding substitui o código cliente, e a mudança apaga mais do que escreve.

As mudanças entre as outras quatro são baratas num sentido que importa: **a imagem é a mesma em
todas elas.** A `shop:1.0` que rodou na lição 7 roda sem mudança nas lições 8, 11 e 18. Levá-la do
Container Apps para o AKS são manifests novos, não código novo; do App Service para o Container Apps,
um recurso novo em volta da mesma imagem. Vale saber disso antes de escrever a primeira linha, e a
lição 22 transforma isso numa decisão sobre lock-in.
