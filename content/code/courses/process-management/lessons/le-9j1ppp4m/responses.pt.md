---
title: Planejando uma resposta
version: 1
---

Para cada risco que vale gerenciar, alguém decide o que fazer com ele. O Guia PMBOK lista as opções como um vocabulário curto, e usá-lo deixa as discussões de risco mais rápidas, porque todo mundo sabe com o que cada palavra compromete.

## Para ameaças

- **Evitar**: mudar o plano para o risco não poder acontecer. Se a API do provedor de pagamento é instável, usar outro provedor, ou deixar o pagamento fora da primeira versão. Evitar um risco costuma custar escopo ou dinheiro; elimina o risco inteiro.
- **Transferir**: passar o impacto para outra pessoa, em geral por contrato ou seguro. Um contrato de preço fixo com um fornecedor transfere o estouro de custo daquela parte para o fornecedor, a um preço. Transferir não torna o risco menos provável; muda quem paga.
- **Mitigar**: reduzir a probabilidade, o impacto, ou os dois. Amostrar e limpar os dados de duas clínicas na primeira Sprint reduz os dois para o risco C; parear um segundo desenvolvedor no faturamento reduz o impacto do risco B.
- **Aceitar**: decidir não fazer nada de antemão, seja **passivamente** — lidar com ele se acontecer — ou **ativamente**, reservando tempo ou dinheiro. Aceitar é a resposta certa para riscos cujas respostas custariam mais do que poupam, como D, a recusa da loja de aplicativos.
- **Escalar**: quando o risco está fora da autoridade do projeto — um congelamento de contratações na empresa, uma mudança regulatória —, passá-lo ao nível que é dono dele, como as exceções do PRINCE2 na aula 7.

## Para oportunidades

O vocabulário tem um espelho para a boa notícia:

- **Explorar**: garantir que a oportunidade aconteça. Pôr um desenvolvedor para testar a biblioteca de calendário na primeira semana.
- **Compartilhar**: trabalhar com um parceiro mais bem posicionado para capturá-la.
- **Melhorar**: aumentar a probabilidade ou o benefício dela.
- **Aceitar**: aproveitá-la se vier, sem esforço.

## Combinando a resposta ao risco

As quatro ameaças do time Agenda recebem quatro respostas diferentes, e os motivos ensinam:

| risco | resposta | por quê |
|---|---|---|
| A — a API muda | mitigar: pôr o provedor atrás de uma interface do próprio time | barato, e limita o impacto a um módulo |
| B — o dev do faturamento sai | mitigar: parear um segundo desenvolvedor no faturamento por duas Sprints | o impacto é grande, e o conhecimento pode ser espalhado |
| C — dados sujos das clínicas | mitigar: amostrar duas clínicas na Sprint 1 | a probabilidade é alta e testar é barato |
| D — a loja recusa o app | aceitar, ativamente: um dia no plano para reenviar | uma resposta custaria mais que o risco |

Cada resposta é ela mesma um pequeno trabalho com custo, e entra no backlog como qualquer outro trabalho. A aula 12 mostra como pesar esse custo contra funcionalidades ao decidir o que vem primeiro.

## Riscos secundários

Uma resposta pode criar riscos novos. Pôr o provedor de pagamento atrás de uma interface própria acrescenta código que pode ter defeitos próprios; transferir trabalho a um fornecedor acrescenta o risco de o fornecedor falhar. Uma resposta só está terminada quando os riscos dela mesma foram olhados.
