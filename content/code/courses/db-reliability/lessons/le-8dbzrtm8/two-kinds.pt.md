---
title: Copiar bytes, ou copiar linhas
version: 1
---

Tudo desde a lição 11 foi **replicação física**: o standby recebe o write-ahead log como o primário o
escreveu e o reaplica numa cópia byte a byte dos arquivos do primário. Isso tem três consequências que
são, ao mesmo tempo, a força e o limite dela. O standby é uma cópia do **cluster inteiro**, de cada banco
e de cada tabela. Ele precisa rodar **a mesma versão major** do PostgreSQL, porque os arquivos e o log
estão no formato dessa versão. E ele é **somente leitura**, porque uma única escrita própria o
transformaria num conjunto diferente de arquivos.

A **replicação lógica** decodifica o mesmo log em **mudanças de linha**, esta linha inserida nesta
tabela, aquela atualizada, e envia essas mudanças. O servidor que as recebe as aplica com inserts,
updates e deletes comuns em tabelas próprias:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas. Física: um primário PostgreSQL 16 manda o write-ahead log, em bytes, para um standby PostgreSQL 16 que guarda uma cópia só de leitura de cada arquivo. Lógica: um publisher PostgreSQL 16 decodifica o log em mudanças de linha das tabelas de uma publicação e as manda para um subscriber PostgreSQL 17, que as aplica em tabelas próprias e aceita escritas.\"><defs><marker id=\"l14k-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">física</text><rect x=\"20\" y=\"46\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primário</text><text x=\"120\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"120\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cluster inteiro</text><rect x=\"500\" y=\"46\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby</text><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada arquivo, só leitura</text><path d=\"M222 81 L498 81\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14k-am)\"></path><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o log, em bytes</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">lógica</text><rect x=\"20\" y=\"166\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">publisher</text><text x=\"120\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"120\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as tabelas de uma publicação</text><rect x=\"500\" y=\"166\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">subscriber</text><text x=\"600\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 17</text><text x=\"600\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabelas próprias, aceita escrita</text><path d=\"M222 201 L498 201\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14k-am)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mudanças de linha</text></svg>", "caption": "O mesmo write-ahead log, enviado de dois jeitos. A replicação física copia bytes para uma cópia da mesma versão; a lógica os decodifica em linhas que qualquer versão consegue aplicar.", "same": ["publisher", "standby", "subscriber"]}
```

| | física | lógica |
|---|---|---|
| o que é copiado | o cluster inteiro, como arquivos | as tabelas que uma publicação nomeia, como linhas |
| versões | a mesma versão major | de qualquer versão suportada para qualquer outra |
| a cópia é | somente leitura, até ser promovida | um servidor comum, que aceita escritas |
| definições de tabela (DDL) | copiadas, como todo o resto | **não copiadas** |
| sequências | copiadas | **não copiadas** |
| para que serve | um standby para onde fazer failover | upgrades, mover algumas tabelas, alimentar outro sistema |

As duas linhas em negrito são o preço, e esta lição paga as duas de propósito. A última linha é o
motivo para pagá-lo: uma cópia lógica pode rodar o **PostgreSQL 17** enquanto o primário roda o 16, o
que transforma um upgrade de versão major de uma indisponibilidade de horas numa troca de minutos.

O vocabulário: uma **publicação** é o conjunto de tabelas que um servidor oferece, uma **subscription**
é o pedido de um servidor para receber uma publicação, e os dois servidores são o **publisher** e o
**subscriber**.
