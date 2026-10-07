---
title: Cinco formas
version: 1
---

A primeira pergunta, *no que estamos trabalhando*, precisa de uma resposta que duas pessoas possam
apontar e discordar. Um parágrafo não faz isso, e um diagrama de arquitetura em geral responde a
outra pergunta: mostra quais caixas existem e qual produto é cada uma, e a modelagem de ameaças
precisa saber **para onde o dado vai e quem encosta nele no caminho**. Isso é um **diagrama de
fluxo de dados (DFD)**, uma notação da análise estruturada dos anos 1970 que a Microsoft adotou
para modelagem de ameaças nos anos 2000 porque ela mostra exatamente isso e nada além.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"A notação. Uma entidade externa é um retângulo: alguém ou algo fora do sistema, como um paciente. Um processo é um círculo: código que transforma dados, como o portal. Um repositório de dados são duas linhas paralelas: dados em repouso, como o banco de prontuários. Um fluxo de dados é uma seta com rótulo: dados em movimento, como um exame enviado. Uma fronteira de confiança é uma linha tracejada: onde o nível de confiança muda, como entre a internet e a nuvem.\"><defs><marker id=\"l02-shapes-tm-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"22.0\" y=\"60.0\" width=\"100.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Paciente</text><circle cx=\"216.0\" cy=\"80.0\" r=\"36\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"216.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal</text><rect x=\"305.0\" y=\"65.0\" width=\"110.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M305.0 65.0 L415.0 65.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M305.0 95.0 L415.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Prontuários</text><path d=\"M452.0 80.0 L556.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-shapes-tm-ah-paper)\"></path><text x=\"504.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">PDF do exame</text><path d=\"M648.0 40.0 L648.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"72.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">entidade externa</text><text x=\"72.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora do sistema;</text><text x=\"72.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você não controla</text><text x=\"216.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">processo</text><text x=\"216.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código que faz</text><text x=\"216.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">algo com dados</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repositório de dados</text><text x=\"360.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dados em repouso:</text><text x=\"360.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma tabela, um bucket</text><text x=\"504.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fluxo de dados</text><text x=\"504.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dados em movimento,</text><text x=\"504.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sempre com rótulo</text><text x=\"648.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fronteira de confiança</text><text x=\"648.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde o nível de</text><text x=\"648.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confiança muda</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Um fluxo tem um processo em pelo menos uma das pontas. Dado não se move sozinho.</text></svg>", "caption": "Cinco formas são a notação inteira. A fronteira é a que transforma um diagrama de fluxo de dados num modelo de ameaças.", "same": ["Portal"]}
```

| forma | o que é | no portal |
|---|---|---|
| **entidade externa** (retângulo) | uma pessoa ou sistema fora do seu controle que manda ou recebe dados | um paciente, a equipe da clínica, o gateway de pagamento, o provedor de SMS |
| **processo** (círculo) | código que você roda, que recebe dados, faz algo com eles e passa adiante | o portal, o console da equipe, o worker de lembretes |
| **repositório de dados** (duas linhas paralelas) | dados em repouso: um banco, um bucket, um arquivo, uma fila, um cache | o banco de prontuários, os arquivos de exames |
| **fluxo de dados** (seta com rótulo) | dados se movendo de um elemento para outro | um PDF de exame enviado, um webhook de pagamento |
| **fronteira de confiança** (linha tracejada) | um lugar onde o nível de confiança muda | entre a internet e a nuvem da Vereda |

Livros mais antigos desenham processos como retângulos de cantos arredondados (Gane e Sarson),
onde este curso desenha círculos (Yourdon e DeMarco). Nada depende de qual você escolher, desde
que um diagrama use só um.

### As regras que fazem disso um DFD

As formas vêm com três regras, e cada uma pega um desenho que parou de descrever dados:

1. **Todo fluxo tem um processo em pelo menos uma das pontas.** Dado não passa de um banco para
   outro sozinho; algum código copia, e é nesse código que as coisas dão errado.
2. **Todo fluxo tem um rótulo que nomeia o dado.** "HTTPS" não é rótulo, porque nomeia o
   transporte e não diz nada sobre o que vai dentro. "PDF do exame" é rótulo.
3. **Um fluxo entre duas entidades externas não é desenhado.** O que um paciente e o gateway de
   pagamento dizem um ao outro acontece fora do seu sistema. Se importa, chega a você por um
   processo, e esse é o fluxo a desenhar.

### O que não entra num DFD

**Fluxo de controle.** Um DFD não tem "se", não tem laço e não tem ordem de passos. "O worker roda
às 20:00 e depois manda os lembretes" é uma sequência, e o DFD só diz que agendamentos vão do banco
para o worker e lembretes vão do worker para o provedor de SMS. Quando a ordem importa para uma
ameaça, um diagrama de sequência ao lado do DFD diz isso.

**Infraestrutura por si só.** Um balanceador de carga, um container ou um servidor só aparece se
faz alguma coisa com o dado que importa, como terminar o TLS e passar HTTP em claro adiante. A
pergunta para cada caixa é se ela muda o que o dado é ou quem pode vê-lo.
