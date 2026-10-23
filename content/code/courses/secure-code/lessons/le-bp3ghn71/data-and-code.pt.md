---
title: Onde o dado vira código
version: 1
---

Uma instrução SQL é um programa pequeno. Quando o portal busca um sobrenome, manda ao banco uma
string como `SELECT … WHERE surname LIKE '%Souza%'`, e o banco **interpreta** essa string para
decidir o que fazer. As aspas em volta de `Souza` fazem parte do programa: dizem ao interpretador onde
um dado começa e onde termina.

**Injeção de SQL é o que acontece quando um valor escrito nessa string muda o lugar onde o dado
termina.** O código queria que o valor fosse dado, e alguns dos caracteres dele foram lidos como SQL.
Não é falha do banco. O banco fez exatamente o que a string dizia; a string dizia algo que quem
desenvolveu nunca escreveu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-split\" aria-label=\"A mesma busca mandada ao banco de dois jeitos. Em cima, o sobrenome D'Ávila é escrito no texto do SQL: o interpretador lê o apóstrofo como o fim da string, tenta ler Ávila como SQL, e falha com erro de sintaxe. Embaixo, o texto do SQL tem um marcador e o valor viaja ao lado: o banco interpreta o texto primeiro, com um buraco onde está o marcador, e depois compara cada sobrenome com o valor, apóstrofo incluído. Nenhum caractere do valor é interpretado.\"><defs><marker id=\"l05-split-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-split-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">escrito no texto</text><rect x=\"20\" y=\"36\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">… WHERE surname LIKE '%D'Ávila%'</text><path d=\"M400 54 L440 54\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-amber)\"></path><rect x=\"440\" y=\"36\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lido como SQL: erro de sintaxe</text><path d=\"M177 90 L177 74\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-amber)\"></path><text x=\"186\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">a string termina aqui</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mandado ao lado do texto</text><rect x=\"20\" y=\"142\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">… WHERE surname LIKE ?</text><rect x=\"20\" y=\"188\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">valor: %D'Ávila%</text><path d=\"M400 160 L440 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-phosphor)\"></path><rect x=\"440\" y=\"142\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">interpretado antes, com um buraco</text><path d=\"M400 206 L440 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-phosphor)\"></path><rect x=\"440\" y=\"188\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">depois comparado, como dado</text></svg>", "caption": "Um marcador mantém o programa e os dados em dois canais, então nenhum valor é interpretado como SQL."}
```

A ideia errada é que injeção trata de entrada hostil, então a defesa seria achar e remover os
caracteres perigosos. O primeiro contraexemplo é uma paciente. O Brasil tem muitos sobrenomes com
apóstrofo, `D'Ávila` entre eles, e a Irlanda e a Itália acrescentam os seus. Uma busca que cola
`D'Ávila` dentro de uma string manda um programa com uma aspa quebrada, e o banco o recusa. **O mesmo
código que quebra com um sobrenome de verdade obedece a qualquer outra coisa que alguém digite**,
porque não sabe distinguir um nome de uma instrução. Remover apóstrofos recusaria o nome da lucia e
ainda deixaria todos os outros jeitos de fechar uma string, na sintaxe de cada banco.

### Dois canais

A correção é parar de montar o programa a partir dos dados. O driver oferece um segundo canal: o
programa vai com **marcadores**, `?` no `sqlite3`, e os valores vão ao lado, como valores. O banco
interpreta o programa **antes** de ver qualquer valor, então nenhum valor consegue mudar o que o
programa é. `D'Ávila` chega como oito caracteres a comparar, apóstrofo incluído.

Isso se chama **consulta parametrizada** (ou instrução preparada, ou parâmetros vinculados; os três
nomes descrevem a mesma ideia em níveis um pouco diferentes). É a defesa que a SQL Injection
Prevention Cheat Sheet da OWASP põe em primeiro lugar, e o ASVS da aula 20 a pede pelo nome.

### O que um marcador não guarda

Um marcador guarda um **valor**: uma string, um número, uma data. Não guarda uma parte do próprio
programa: um nome de tabela, um nome de coluna, a direção de uma ordenação, a palavra `ASC`. Esses
ainda precisam ser escritos no texto do SQL, e quando vêm de uma requisição precisam da defesa da aula
2: uma **lista de permissão** que liga o que a requisição pode pedir a um texto que o próprio código
escreveu.

O resto desta aula são essas duas regras na busca de pacientes do portal, mais uma armadilha que
sobrevive à correção, e as mesmas regras num ORM.
