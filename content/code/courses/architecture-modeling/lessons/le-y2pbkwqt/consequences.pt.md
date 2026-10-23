---
title: Consequências, inclusive as que você preferia não escrever
version: 1
---

**A seção de consequências diz o que passa a ser verdade quando a decisão entra em vigor: o que fica
mais fácil, o que fica mais difícil e que trabalho ou risco novo a decisão cria.** É a parte que
mais vezes fica magra, porque escrever as consequências ruins da própria decisão parece argumentar
contra ela. É também a parte que melhor protege a decisão.

## Três tipos, todos escritos

Para os bloqueios de assento no Redis, Tainá escreveu:

- **Positivas.** O tráfego de bloqueios sai do banco de reservas; no pico seguinte, a CPU do banco
  caiu de 85% para 52%. A expiração é tratada pelo próprio Redis, então o job de limpeza é apagado.
- **Negativas.** Um reinício do Redis sem persistência perde todos os bloqueios em andamento. Os
  passageiros que estiverem pagando nesse momento veem *assento não está mais bloqueado* e precisam
  escolher de novo. Aceitamos isso: um bloqueio perdido custa um minuto ao passageiro, e os bloqueios
  são recriados em segundos.
- **Neutras, mas trabalho novo.** O serviço de reservas agora precisa conferir o bloqueio no Redis
  antes de gravar uma reserva, e tratar o Redis fora do ar recusando bloqueios novos em vez de pular
  a conferência. A Plataforma inclui o Redis no runbook de plantão.

O parágrafo das negativas é o que vai importar. Quando o Redis reiniciar durante um deploy, dois
meses depois, e alguém perguntar *por que quarenta passageiros perderam o assento?*, o registro já
responde: **era um custo conhecido e aceito**, escolhido contra as alternativas por razões
declaradas. Sem ele, o mesmo incidente parece um erro, e a decisão é revertida às pressas por gente
que não sabe o que ela estava protegendo.

## Consequências são afirmações que dá para conferir depois

Uma boa consequência é específica o bastante para se mostrar verdadeira ou falsa: *a CPU cai abaixo
de 60% no pico*, *bloqueios perdidos ao reiniciar*. É isso que transforma o log de decisões em algo
que se pode revisar, e a aula 13 usa isso: uma revisão de arquitetura pergunta, para cada registro
importante, se as consequências dele se confirmaram. Um registro cujo benefício previsto nunca
chegou é candidato a ser substituído.

## O que não entra

- **Passos de implementação.** *Criar o cliente Redis, adicionar uma feature flag, migrar na terça*
  é um plano. Aponte para o ticket.
- **Repetir a decisão.** *Vamos usar Redis* não é consequência de decidir usar Redis.
- **Desejos.** *Isto vai deixar o sistema mais escalável* é uma esperança sem medida. Diga o que vai
  escalar, até onde, e como alguém saberia.
