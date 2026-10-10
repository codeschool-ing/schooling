---
title: Documentação que pessoas leem
version: 1
---

**A página que uma pessoa desenvolvedora lê é desenhada a partir do mesmo arquivo que o teste
confere.** Ninguém a escreve. Um renderizador, um programa JavaScript rodando num navegador, lê o
`openapi.yaml` e monta uma entrada por operação, com os parâmetros, o corpo da requisição, as
respostas e os schemas por trás deles. Mude o documento e a página muda no próximo carregamento,
então uma página desenhada assim é exatamente tão atual quanto o documento que o teste de contrato
mantém honesto.

Dois renderizadores cobrem quase tudo o que você vai encontrar:

| | Swagger UI | Redoc |
|---|---|---|
| layout | um painel expansível por operação, agrupado por tag | três colunas: navegação, explicação, exemplos |
| enviar requisições | sim: **Try it out** preenche um formulário e manda uma requisição real do navegador | não; é uma referência para ler |
| serve para | quem explora uma API enquanto constrói contra ela | documentação publicada para quem é de fora |

Os dois leem o mesmo documento sem mudança. As palavras na página são as do documento: cada
`summary` vira um título, cada `description` um parágrafo, e um `example` ao lado de um schema vira a
amostra que o leitor copia. **Uma página é tão boa quanto esses campos**, e um documento com tipos e
sem descrições vira uma lista de nomes de campo com que ninguém consegue agir. O do shelf tem um
resumo em cada operação e uma descrição em cada resposta, e nada mais longo, porque a API é pequena.
Uma maior precisa de um parágrafo sobre o que cada erro quer dizer e quando acontece.

## Olhando o do shelf

Nada disto foi rodado para a aula: a máquina em que ela foi gravada não tem navegador, e por isso
não há captura de tela aqui. O que vem a seguir é como você pode olhar o seu.

A VM não tem área de trabalho, então o navegador é o do seu próprio computador. O jeito mais rápido
não precisa de instalação nenhuma. Imprima o documento na VM com `cat openapi.yaml` e copie do
terminal. Cole na metade esquerda do Swagger Editor, em `editor.swagger.io`, e a metade direita é o
Swagger UI, desenhado a partir do que você colou. O Swagger Editor é uma página que outra pessoa
mantém no ar. O documento do shelf não descreve nada privado, mas a API interna de uma empresa seria
descrita a um estranho desse jeito, e para essas as mesmas ferramentas existem como programas que você
roda por conta própria.

## Por que o "Try it out" não alcança o shelf

Abra uma operação, aperte **Try it out** e envie, e ela falharia. Isso também não foi rodado, mas
cada um dos três motivos dá para ver sem navegador, e nenhum deles tem a ver com o documento.

O `servers` do documento diz `http://127.0.0.1:8000/v1`. Num navegador no seu computador,
`127.0.0.1` é o seu computador, e o shelf não está rodando ali. Ele roda dentro da VM, que tem um
endereço próprio numa rede que o seu computador compartilha com ela. `multipass info api` o mostra,
na linha `IPv4`, e dentro da VM `ip -4 addr` o mostra, seja qual for o hipervisor.

Trocar o `servers` por esse endereço não basta, porque o `rest.py` escuta em `127.0.0.1` dentro da VM,
que é o loopback da própria VM. A aula 1 escolheu isso para que nada de fora da máquina alcance a
API, e vale para o seu navegador também. Um servidor que deve ser alcançado de fora precisa escutar
num endereço que o lado de fora alcance: o da própria VM, ou `0.0.0.0` para todos eles. O curso
deixa o `rest.py` como está.

E mesmo escutando no endereço certo, a página é servida de uma origem e o shelf de outra, então o
navegador pergunta ao shelf, por meio de cabeçalhos CORS, se a página pode ler as respostas dele.
Para um POST com corpo JSON ele pergunta antes com uma requisição `OPTIONS`, que o `rest.py` responde
com o 501 que o teste de contrato achou. Essa conversa, e como um servidor deve responder a ela, é a
aula 13.

**Então a página é para ler, e o `curl` continua sendo a ferramenta para chamar o shelf neste
curso.** Ler é o que a página faz melhor, de todo modo. O painel de `POST /books` mostraria os
cinco campos obrigatórios, o `stock` opcional e as quatro recusas com os seus significados, que é o
que quem escreve um cliente quer ver antes da primeira linha.
