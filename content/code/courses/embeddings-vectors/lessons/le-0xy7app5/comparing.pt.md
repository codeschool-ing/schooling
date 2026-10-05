---
title: Quem roda, e quem paga
version: 1
---

É tentador comparar bancos de vetores pela velocidade, e no tamanho da Marginalia essa comparação
não tem o que medir: quarenta artigos são poucos o bastante para qualquer um deles buscar, ou para a
linha de NumPy da aula 3. **A pergunta que decide é onde o banco roda e quem o mantém de pé**, e os
três produtos desta aula respondem a ela de três jeitos diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três jeitos de um banco de vetores rodar. No seu processo: uma caixa, o seu programa, contém o seu código e a biblioteca do Chroma, que lê e grava o diretório chroma na mesma máquina. Num servidor que você roda: os seus programas chegam por HTTP a um processo servidor, chroma run ou Weaviate, e o servidor é dono dos arquivos; tudo isso fica dentro da fronteira das máquinas que você opera. Nas máquinas do fornecedor: o seu programa manda requisições HTTPS com uma chave de API através da fronteira para um serviço como Pinecone, Weaviate Cloud ou Chroma Cloud, que você não opera.\"><defs><marker id=\"shpt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">no seu processo</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"250\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que você opera</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"130\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu programa</text><rect x=\"55\" y=\"95\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seu código</text><rect x=\"55\" y=\"140\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Chroma (biblioteca)</text><path d=\"M120 170 L120 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shpt-ah0)\"></path><rect x=\"55\" y=\"222\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">diretório chroma/</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">num servidor que você roda</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"250\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que você opera</text><rect x=\"280\" y=\"60\" width=\"160\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seus programas</text><path d=\"M360 100 L360 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shpt-ah0)\"></path><text x=\"368\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP</text><rect x=\"280\" y=\"140\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processo servidor</text><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chroma run · Weaviate</text><path d=\"M360 190 L360 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shpt-ah0)\"></path><rect x=\"295\" y=\"222\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">os arquivos dele</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\" font-weight=\"600\">nas máquinas do fornecedor</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"80\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que você opera</text><rect x=\"520\" y=\"52\" width=\"160\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu programa</text><path d=\"M600 84 L600 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#shpt-ah0)\"></path><text x=\"608\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTPS + chave de API</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"140\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"600\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o que eles operam</text><rect x=\"520\" y=\"168\" width=\"160\" height=\"84\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o serviço</text><text x=\"600\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Pinecone</text><text x=\"600\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Weaviate Cloud</text><text x=\"600\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Chroma Cloud</text></svg>", "caption": "Três lugares onde um banco de vetores pode rodar. Tudo dentro de uma linha tracejada cinza é seu para implantar, guardar cópia e reiniciar; na terceira forma o banco fica dentro da linha do fornecedor."}
```

**No seu processo**, o banco é uma biblioteca e um diretório. O `PersistentClient` do Chroma tem
essa forma. Nada para implantar e nada a que se conectar; o preço é que um programa é dono dos
arquivos, e o banco só está disponível enquanto aquele programa e aquele disco estiverem. A cópia de
segurança é uma cópia do diretório, feita enquanto nada grava nele.

**Num servidor que você roda**, o banco é um processo que vários programas alcançam pela rede:
`chroma run`, ou o Weaviate num contêiner. Muitos clientes podem compartilhar uma cópia, e o
servidor pode morar numa máquina do tamanho certo para ele. Agora você o opera: atualizações,
reinícios, espaço em disco, cópias de segurança e monitoramento são seus.

**Nas máquinas do fornecedor**, o banco é uma API com uma chave. O Pinecone tem só essa forma; o
Chroma Cloud e o Weaviate Cloud a oferecem ao lado das versões de código aberto. Ninguém do seu lado
opera nada, o índice cresce sem você, e a conta cresce junto. Os seus artigos e os vetores deles
saem das suas máquinas. A aula 1 disse que o vetor da mensagem de um cliente é dado pessoal como a
mensagem, então isso é uma questão de contrato e de privacidade antes de ser uma questão técnica.

## Lado a lado

| | Chroma | Pinecone | Weaviate |
|---|---|---|---|
| onde roda | no seu processo, num servidor seu ou no Chroma Cloud | no serviço do Pinecone | num servidor seu, no Weaviate Cloud ou embutido pelo cliente |
| código | aberto | um serviço comercial | aberto |
| quem gera os vetores | o cliente, com um modelo padrão, ou você | você, ou um índice ligado a um modelo do Pinecone | você, ou um módulo vetorizador no servidor |
| fixado na criação | o espaço | a dimensão e a métrica | os tipos das propriedades e a métrica do índice vetorial |
| o que a consulta devolve | uma distância | uma nota, a mais alta primeiro para cosseno | uma distância |
| filtros | `where` nos metadados, `where_document` no texto | um filtro de metadados, e namespaces | `Filter` sobre propriedades tipadas |
| palavras e vetores juntos | não usado nesta aula | não usado nesta aula | `query.hybrid` com `alpha` |
| pelo que você paga | as suas máquinas, ou o Chroma Cloud | o que você guarda, lê e grava | as suas máquinas, ou o Weaviate Cloud |

Leia a tabela como uma lista de perguntas a fazer a qualquer banco de vetores, e não como uma
classificação: esses três mudam com frequência, e você vai conferir a linha que mais importa na
documentação atual de qualquer jeito.

## Para a Marginalia

A central de ajuda são quarenta artigos e um programa. Um diretório do Chroma ao lado desse programa
dá conta, e no dia em que a loja rodar vários servidores web, `chroma run` serve o mesmo diretório
sem mudar uma linha do código de busca. Um serviço hospedado começa a se pagar quando a coleção é
grande, o tráfego é irregular e ninguém do time quer ser acordado por um banco de dados. Nada disso
vale para a Marginalia ainda.

Faltam duas formas. A aula 13 apresenta o FAISS, uma biblioteca que é só um índice; o LanceDB, um
banco embutido que guarda os dados em arquivos colunares; e o Qdrant. A aula 14 põe os vetores no
PostgreSQL, o banco que uma loja como esta provavelmente já roda.
