---
title: As correntes subterrâneas
version: 1
---

**Algumas preocupações não pertencem a nenhuma etapa de um pipeline, porque correm por baixo de todas
elas.** Joe Reis e Matt Housley, em *Fundamentals of Data Engineering* (O'Reilly, 2022), as chamam de
**undercurrents**, correntes subterrâneas, e a palavra é deles. Eles citam seis. A imagem tentadora é
a de fases posteriores: construir o pipeline, depois protegê-lo, depois documentá-lo, depois
automatizá-lo. Cada corrente é, na verdade, uma pergunta feita em todas as etapas, e uma etapa que a
pulou entrega o buraco para a seguinte.

| corrente | a pergunta que ela faz em toda parte | na Roda Livre |
|---|---|---|
| **segurança** | quem pode ler e alterar isto, e são o mínimo de pessoas que precisam? | a fonte de pagamentos legível por duas pessoas, não por todo analista |
| **gestão de dados** | o que isto quer dizer, de onde veio, quem é o dono, está certo? | uma tabela aceita como *a* lista de viagens, com um dono nomeado |
| **DataOps** | está automatizado, vigiado, e se recupera rápido quando quebra? | a conferência matinal de que ontem chegou, feita por um programa e não por Davi |
| **arquitetura de dados** | como as peças se encaixam, e do que cada escolha abriu mão? | onde moram as tabelas analíticas, o que esta aula pontua |
| **orquestração** | o que roda quando, em que ordem, e o que acontece quando um passo falha? | o relatório por estação começando só depois que as viagens chegaram |
| **engenharia de software** | é código em controle de versão, revisado e testado? | o script de carga no git, com um teste que lhe dá uma coluna renomeada |

## Por que "por baixo" e não "depois"

Pegue a segurança. Uma decisão tomada quando as viagens são copiadas pela primeira vez, digamos, que a
cópia guarda o telefone de cada cliente, não fica naquela etapa. Toda tabela feita a partir da cópia
passa a ter o número também, todo relatório que lê essas tabelas pode mostrá-lo, e toda pessoa com
acesso a qualquer uma delas pode lê-lo. **Corrigir no fim quer dizer encontrar cada cópia**; decidir no
começo que a cópia nunca leva o número quer dizer que não há nada para encontrar.

A orquestração tem a mesma forma, na outra direção. Um agendamento não é uma etapa própria: a cópia, a
limpeza e o relatório precisam, cada um, de uma hora para rodar e de uma regra para quando o passo
anterior atrasa. `pipelines-etl` é o curso sobre isso.

## Onde elas aparecem neste curso

O ciclo de vida sob o qual as correntes correm é a aula 3: geração, ingestão, armazenamento,
transformação e entrega, desenhados de ponta a ponta com estas seis por baixo. Elas voltam pelo nome
ao longo do curso:

- segurança e gestão de dados são as verificações na porta da aula 7 e a sua seção sobre privacidade;
- DataOps é cada lugar em que um programa confere o próprio trabalho, a começar pela verificação de
  atualidade desta aula;
- arquitetura de dados é a segunda metade desta aula, e as aulas 9 e 10;
- engenharia de software é o hábito que a aula 1 começou: todo programa deste curso é um arquivo que
  você pode ler, guardar no git e rodar de novo.

A lista é o jeito de um livro dividir o trabalho, e outros autores dividem de outro jeito. A utilidade
dela é como lista de verificação: **para qualquer etapa, faça as seis perguntas**, e a que ninguém
sabe responder costuma ser o próximo incidente.
