---
title: As faixas do Google Play
version: 1
---

**O Google Play dá a todo app quatro lugares para pôr um release, e um release em cada um chega a
um grupo diferente de pessoas.** Eles se chamam **faixas** (tracks), e formam uma escada: quanto
mais baixa a faixa, menos pessoas e mais tolerantes. *Lido na Central de Ajuda do Play Console como
publicada em 2025, que a máquina de gravação não conseguiu abrir; não rodado.*

| faixa | quem recebe | como entra | revisão |
|---|---|---|---|
| **teste interno** | até 100 testadores que você nomeia | uma lista de e-mails, e um link de inscrição | a mais rápida; disponível aos testadores minutos depois do envio |
| **teste fechado** | os grupos ou listas de e-mail que você escolhe | um link de inscrição, ou um Google Group | revisada como um release |
| **teste aberto** | qualquer pessoa que entre pela página da loja | um botão *Participar do beta* na ficha | revisada como um release |
| **produção** | todo mundo, ou uma porcentagem de todo mundo, lição 8 | instalando pela loja | revisada |

## Por que quatro e não duas

Cada degrau amplia o público e muda o custo de um bug. Um build interno quebrando custa um minuto
a um colega; um beta aberto quebrando custa avaliações de estranhos, que testadores abertos podem
deixar em privado e que ainda doem. **A escada existe para que a primeira pessoa a encontrar um
crash seja a mais barata.** Uma equipe que envia direto para produção pula todos os degraus e
descobre pela nota da loja.

## A regra para uma conta pessoal nova

A lição 3 já a encontrou: a ajuda do Google em 2025 exigia que uma conta pessoal de desenvolvedor
nova rodasse um **teste fechado com pelo menos 12 testadores por pelo menos 14 dias** antes do
acesso à produção. Para essas contas a faixa fechada não é opcional; ela é a porta.

## Testadores em mais de uma faixa

Uma pessoa pode ser testadora em várias faixas ao mesmo tempo, e estar na produção como usuária
comum. **O Google Play entrega a ela o release com o version code mais alto entre as faixas que ela
enxerga.** Uma colega nas faixas interna e fechada recebe o build que for mais novo, o que quase
sempre é o que você quer, e surpreende no dia em que o build interno é mais antigo que o fechado e a
colega jura que está testando a correção. A seção "Um build, promovido" roda exatamente esse caso.
