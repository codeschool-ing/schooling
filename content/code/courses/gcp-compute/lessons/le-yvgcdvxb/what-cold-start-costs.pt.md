---
title: O que uma partida a frio custa de verdade
version: 1
---

Uma partida a frio é a espera de uma requisição que chega quando nenhuma instância está livre para
pegá-la. **Ela é a soma de três coisas, e só uma delas é sua para encurtar de verdade: o que o seu
programa faz antes de escutar.** As outras duas, levar a imagem até a máquina e subir o contêiner,
são do Cloud Run, e o Google passou anos as deixando pequenas.

## As três partes

**A imagem.** O Cloud Run busca a imagem no Artifact Registry. A documentação do Google diz que ele
transmite as imagens de modo que um contêiner pode subir antes de a imagem inteira chegar, e é por
isso que o tamanho da imagem importa menos do que a intuição diz, embora uma imagem menor ainda
ajude. A lição 21 trata do registro.

**O contêiner.** O runtime sobe, uma caixa de areia em volta do contêiner é montada, o processo
começa. Essa parte é da plataforma e é curta.

**O seu programa, até escutar.** Imports, configuração, conexões, caches aquecidos, um modelo
carregado. Essa é a parte que varia de alguns milissegundos a um minuto, e **ela é inteiramente
sua**.

## Medindo em casa

Este laptop não consegue medir as duas primeiras partes do Cloud Run, e nada aqui finge que
consegue. O que ele mede é a última parte, e uma subida de contêiner, que é da mesma ordem de
grandeza. A partir de `~/gcp`, inicie o serviço de pedidos e espere até o `/health` responder, tudo
dentro de um `time`:

```
ana@laptop:~/gcp$ time (docker run -d --name orders-cold -p 8080:8080 orders:1 > /dev/null; until curl -sf localhost:8080/health > /dev/null; do sleep 0.02; done)

real	0m0.537s
user	0m0.063s
sys	0m0.050s
ana@laptop:~/gcp$ time curl -s localhost:8080/health
{"status": "ok"}
real	0m0.007s
user	0m0.005s
sys	0m0.000s
```

**Neste laptop, do `docker run` até a primeira resposta levou cerca de meio segundo**, e a requisição
seguinte, a uma instância quente, poucos milissegundos. Quase todo esse meio segundo é o contêiner e
o Python subindo; o serviço de pedidos em si não faz nada antes de escutar.

Agora a parte que varia. Os imports de um programa fazem parte da subida, e uma biblioteca grande
custa tempo de verdade. Compare importar o cliente de Pub/Sub do Google, que a lição 17 usa, com
importar o que o serviço de pedidos precisa:

```
ana@laptop:~/gcp$ python3 -X importtime -c 'import google.cloud.pubsub_v1' 2>&1 | tail -1
import time:       311 |     300167 | google.cloud.pubsub_v1
ana@laptop:~/gcp$ time python3 -c 'import google.cloud.pubsub_v1'

real	0m0.376s
user	0m0.322s
sys	0m0.048s
ana@laptop:~/gcp$ time python3 -c 'import json, http.server'

real	0m0.053s
user	0m0.032s
sys	0m0.021s
```

O `-X importtime` informa cada módulo que o Python carrega e quanto cada um levou, em
microssegundos; a última linha é o total do pacote pedido, 300.167 microssegundos. **Subir o Python
e importar o cliente de Pub/Sub levou 0,38 segundo neste laptop; subir o Python e importar o que o
serviço de pedidos precisa levou 0,05.** Um serviço que importa uma dúzia de bibliotecas desse
tamanho na subida acrescentou segundos a cada partida a frio antes de fazer qualquer coisa, e no
Cloud Run cada instância paga isso uma vez.

## Encurtando a sua parte

As mudanças que importam são as do seu programa, na ordem de quanto costumam render:

1. **Faça menos antes de escutar.** Carregue o que a primeira requisição precisa e adie o resto
   para o primeiro uso; abra a conexão com o banco quando ela for pedida pela primeira vez e não no
   import.
2. **Importe menos.** Uma dependência usada por um endpoint raro pode ser importada dentro desse
   endpoint.
3. **Deixe na imagem só o que roda.** Uma base enxuta e nenhuma ferramenta de build na imagem
   final, que os builds em vários estágios do curso `docker` cobrem.

A seção 05 trata das duas configurações que escondem uma partida a frio em vez de encurtá-la: uma
instância mínima quente e uma CPU mais rápida na subida.
