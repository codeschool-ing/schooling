---
title: Ingestão: copiar para fora sem perturbar a origem
version: 1
---

**Ingestão é a cópia do sistema que fez o dado para o lugar onde o time de dados o guarda, e a
primeira regra dela é não mudar nada no caminho.** Nada de renomear, filtrar ou corrigir. Uma linha
que parece errada é copiada errada, porque a cópia é a prova do que a origem disse, e decidir o que
está errado é trabalho de uma etapa posterior, feito onde pode ser desfeito.

A segunda regra é **deixar a origem como você a encontrou**. O banco do aplicativo existe para
destravar bicicletas; uma cópia que o deixa lento às seis da tarde quebrou a coisa que paga por todo
o resto. O programa da seção 08 abre o banco do aplicativo só para leitura,
então não conseguiria mudar uma linha nem se tentasse. A aula 4 dá nome às ferramentas maiores para a
mesma regra: uma réplica para ler, e a leitura do próprio log de mudanças do banco.

Toda ingestão responde a três perguntas, e cada resposta tem um nome.

## Quem começa a cópia: pull ou push

| | como funciona | na Roda Livre |
|---|---|---|
| **pull** (puxar) | o programa do time de dados vai lá e pede, no horário dele | toda noite, um programa lê as viagens do dia no banco do aplicativo |
| **push** (empurrar) | a origem manda o dado quando o tem, para um endereço que o time de dados mantém | os sensores das docas mandam cada leitura quando ela acontece; o provedor de pagamentos chama um endereço quando uma cobrança passa |

**Com pull, quem decide quando é o time de dados; com push, é a origem**, e o time de dados tem de
estar ouvindo quando o dado chega. Uma origem puxada que está fora do ar pode ser consultada de novo
dali a uma hora. Uma leitura empurrada que chega enquanto o receptor está fora se perde, a menos que
quem mandou tente de novo.

## Quanto é copiado: completa ou incremental

**Uma carga completa copia a tabela inteira toda vez. Uma carga incremental copia só o que é novo
desde a última cópia.** A Roda Livre tem as duas, por bons motivos:

- a tabela de **estações** tem doze linhas e muda poucas vezes por ano. Copiar tudo toda noite não
  custa nada e nunca perde uma mudança;
- a tabela de **viagens** cresce umas duzentas linhas por dia e vai ter milhões. Copiar tudo toda
  noite copiaria as mesmas viagens antigas de novo e de novo, então o programa copia **um dia**: as
  viagens que começaram na data que ele recebe.

A incremental é mais barata e tem um porém que a completa não tem. Ela precisa saber o que "novo"
quer dizer, e uma linha que muda depois de copiada — uma viagem de segunda estornada na quarta — não
é nova pela data e se perde. A aula 7 trata exatamente disso: copiar pelo horário da última mudança
de cada linha, e a sobreposição que pega uma mudança gravada com atraso.

## Com que frequência: lote ou fluxo

Uma cópia que roda uma vez por noite sobre um dia fechado é um **lote** (batch). Uma cópia que trata
cada leitura de sensor segundos depois de ela chegar é um **fluxo** (stream). O relatório da manhã de
Marta precisa de ontem, então um lote noturno basta; um mapa de quais docas estão vazias agora não
bastaria. A aula 8 é sobre a diferença, e sobre o que um fluxo custa.

## Pousar o dado bruto

**O lugar onde a cópia chega se chama zona de pouso, ou simplesmente bruto (raw)**, e ela é gravada
num formato o mais próximo da origem que o formato permite. O programa desta aula grava cada tabela
como **JSON Lines** — um objeto JSON por linha, uma linha por registro, com os mesmos nomes de coluna
que o aplicativo usa — num diretório com o nome do dia:

```
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
```

O dia no caminho é como uma etapa posterior acha a segunda-feira, e como uma nova execução substitui
a segunda sem tocar no domingo. Por que a cópia bruta é guardada e nunca editada é o assunto da
próxima seção.
