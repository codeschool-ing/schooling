---
title: No que o Node é bom, e no que não é
version: 1
---

**O Node roda o seu JavaScript em uma thread só, e foi construído em torno de nunca deixar essa
thread esperando.** Tudo o que ele tem de bom em um servidor, e a única coisa em que ele é ruim,
vem dessa frase.

## Um servidor passa a maior parte do tempo esperando

Pense no que faz uma requisição à API de uma loja online. Ela lê o pedido, pergunta um produto ao
banco de dados, espera a resposta, talvez pergunte um preço a um segundo serviço, espera de novo, e
escreve a resposta. O código que roda leva muito pouco tempo. **A espera é a maior parte da vida da
requisição**, e nada em esperar precisa de processador.

Um servidor tradicional dá a cada requisição uma thread própria, e uma thread que espera fica ali
segurando memória até a resposta chegar. O Node faz o contrário. O seu código pede a resposta do
banco, entrega ao Node uma função para chamar quando ela vier, e retorna. A thread fica livre na
mesma hora para rodar o código da próxima requisição que tiver algo a fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três requisições ao longo do tempo. Cada uma roda um trecho curto de JavaScript, espera muito tempo pelo banco de dados e roda outro trecho curto para responder. Na linha de baixo, a única thread de JavaScript roda esses trechos um depois do outro, e fica livre enquanto as três esperam.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição A</text><rect x=\"150\" y=\"28\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"184\" y=\"34\" width=\"232\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"420\" y=\"28\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição B</text><rect x=\"200\" y=\"78\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"234\" y=\"84\" width=\"142\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"380\" y=\"78\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição C</text><rect x=\"250\" y=\"128\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><rect x=\"284\" y=\"134\" width=\"232\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"520\" y=\"128\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><line x1=\"140\" y1=\"172\" x2=\"700\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a única thread</text><text x=\"20\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">de JavaScript</text><rect x=\"140\" y=\"194\" width=\"560\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"420\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"200\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"380\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"250\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><rect x=\"520\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><line x1=\"140\" y1=\"256\" x2=\"700\" y2=\"256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,256.0 692.6,259.1 692.6,252.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"150\" y=\"262\" width=\"20\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu código rodando</text><rect x=\"330\" y=\"263\" width=\"30\" height=\"10\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"366\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando o banco de dados</text></svg>", "caption": "A maior parte da vida de uma requisição é espera, e esperar não precisa de thread. A única thread roda o trecho de código que estiver pronto a seguir."}
```

Assim, um processo Node consegue segurar milhares de requisições, cada uma esperando alguma coisa,
sem nenhuma thread por requisição. É aí que ele se encaixa: **trabalho que é principalmente entrada e
saída** — APIs na frente de um banco de dados, um serviço que chama outros serviços, um proxy, um
servidor de chat segurando conexões abertas, qualquer coisa que leve dados de um lugar para outro.

## Um servidor que calcula

A mesma imagem mostra o ponto fraco. Se o trecho curto de código da requisição A não for curto, se
ele redimensionar uma imagem, calcular o hash de uma senha com custo alto ou ordenar um milhão de
linhas, a thread fica ocupada esse tempo todo e **B e C esperam, por mais prontas que estejam**.
Nada mais no processo roda até o código de A retornar. A aula 2 faz um servidor fazer isso de
propósito e mede quanto custa para as outras requisições.

Isso não é motivo para evitar o Node. É motivo para saber para onde vai o trabalho pesado. A aula 10
dá ao Node mais de uma thread quando você precisa: worker threads para calcular, processos filhos
para outros programas, e modo cluster para um processo por processador.

## Mais duas coisas que ele dá

**Uma linguagem dos dois lados.** O navegador roda JavaScript e nada mais, então uma equipe que
escreve o servidor em Node escreve uma linguagem só em todo lugar, pode compartilhar o código que
valida um formulário nos dois lados, e muda pessoas entre as duas metades da aplicação sem uma
segunda linguagem para aprender. É uma vantagem real e modesta: a metade do servidor ainda tem o
próprio runtime e as próprias bibliotecas, que são o resto deste curso.

**npm.** O registry que você conheceu na aula 21 do javascript é onde quase toda biblioteca para Node
é publicada, do framework web das aulas 6 e 7 aos drivers de banco de dados que cursos mais à frente
usam. A aula 4 trata de conviver com ele em um servidor, onde o código que você instala roda com as
permissões do seu servidor.

## Como este curso roda as coisas

Toda aula roda programas de verdade no seu computador e mostra o que eles imprimiram. Um servidor
neste curso escuta em `127.0.0.1`, um endereço que só o seu próprio computador alcança, e você
pergunta coisas a ele com `curl` a partir de um segundo terminal. Nada nele fica aberto para a rede,
e não é preciso nada além do que a seção depois da próxima instala.
