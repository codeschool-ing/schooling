---
title: Quando uma função é a resposta errada
version: 1
---

Uma função é a ferramenta certa quando o trabalho chega em picos, termina rápido e não precisa lembrar
de nada. **Cada caso abaixo quebra uma dessas três condições**, e cada um apareceu numa seção
anterior desta aula.

- Tarefas longas. Uma transcodificação de vídeo de uma hora ou um lote de quarenta minutos não cabem
  no teto de 15 minutos do Lambda, e uma computação pesada bate no limite de tempo de CPU do Workers
  bem antes. Cortar a tarefa em etapas é possível, e é uma arquitetura por si só; um contêiner ou uma
  máquina costuma ser a resposta mais simples.
- Carga alta e constante. O cruzamento pôs isso em dólares: com dezenas de requisições por segundo, o
  dia inteiro, todo dia, uma ou duas máquinas custam menos que a função.
- Estado pesado. Um cache aquecido ao longo de horas, um modelo grande guardado na memória, um
  servidor de jogo segurando uma sala: trabalho cujo valor está no que o processo lembra é trabalho
  que uma função foi feita para esquecer.
- Latência rígida com tráfego esparso. Quando toda requisição precisa ser rápida e as requisições são
  poucas, os cold starts caem em usuários de verdade. A provisioned concurrency resolve pagando por
  cópias ociosas, e aí a função vira de novo uma máquina, com outra conta.
- Portabilidade. A assinatura de um handler, os formatos de evento, os gatilhos e as permissões são de
  um fornecedor. **A lógica dentro de uma função pode ficar portável; a fiação em volta dela, não.**
  Levar uma função do Lambda para o Workers é reescrever as bordas dela, e um sistema com duzentas
  delas é um projeto de migração.

Nenhum desses é motivo para evitar funções. São os motivos para escolhê-las nas partes de um sistema
que têm o formato certo, e não no resto. É assim que a maioria dos sistemas acaba: algumas máquinas
ou contêineres para o núcleo constante, e funções em volta para o que chega em picos.

::: track data
Num pipeline de dados, o primeiro uso natural de uma função é o que esta aula desenhou entre os
gatilhos: **um arquivo cai num bucket, e uma função dispara para conferi-lo, registrá-lo ou começar a
carga.** Isso se encaixa bem: acontece algumas vezes por hora, é curto, e ninguém está esperando. A
transformação pesada que vem depois em geral não se encaixa, porque roda por muito tempo e segura
muita coisa na memória. O `pipelines-etl`, o próximo curso desta trilha, continua o pipeline a partir
desse primeiro evento.
:::

::: track software-architecture
**Adotar serverless é uma decisão de arquitetura, não uma escolha de hospedagem.** O sistema passa a
ser orientado a eventos, cortado em muitas unidades pequenas publicadas em separado, que conversam por
filas, buckets e gateways em vez de chamadas dentro de um processo. Isso compra escalar e publicar
cada parte por conta própria, e custa um sistema mais difícil de ver inteiro, de rastrear de ponta a
ponta e de rodar numa máquina só. O runtime do fornecedor, os formatos de evento dele e os limites
dele viram uma dependência do desenho, e entram no registro de decisão como qualquer outra
dependência.
:::

::: track *
A versão curta: **serverless é excelente em trabalho em picos, no formato de eventos, e fraco em
trabalho constante e longo.** Uma API calma na maior parte do dia, um arquivo para processar quando
chega e uma tarefa agendada são o formato dele. Quando o trabalho não tem esse formato, uma máquina ou
um contêiner é a resposta mais simples.
:::
