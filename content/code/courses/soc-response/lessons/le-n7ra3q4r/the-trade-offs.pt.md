---
title: As trocas, e quem decide
version: 1
---

O NIST SP 800-61 nomeia as perguntas que uma estratégia de contenção precisa responder, e elas são uma lista
de conferência melhor do que qualquer regra isolada:

- Quanto **dano**, ou **roubo**, ainda é possível se nada for feito?
- Que **evidência** precisa ser guardada, e esta ação destrói alguma?
- Qual **serviço** para, e para quem?
- Quanto **tempo e esforço** a ação custa?
- Quão **eficaz** ela é: fecha a entrada, ou uma de várias?
- Quanto tempo ela deve durar: uma medida de **emergência** por horas, **temporária** por dias, ou
  **permanente**?

Ninguém responde isso sozinho. Os analistas **propõem**: sabem o que a ação faz tecnicamente. A líder do
incidente **decide**, dentro da autoridade que o plano lhe dá. E uma decisão que para parte do negócio, como
tirar o servidor de arquivos da rede por um dia, vai para a **patrocinadora executiva**, porque é uma decisão
de negócio com uma descrição técnica. A aula 11 escreveu esses papéis para isso não precisar ser negociado às
nove da manhã com dados saindo.

Há mais uma opção na mesa, e ela é real: **observar antes de agir.** Algumas equipes deixam um invasor no lugar
por um tempo para aprender o que ele procura e quantas entradas tem. É uma decisão de custo alto, mais dano
enquanto se observa, e pertence à líder junto com o jurídico, nunca a um analista que acha que seria
interessante. Na quinta não há nada a ganhar: os dados já saíram, a entrada é conhecida, e cada hora de espera
é uma hora em que a conta do bruno ainda funciona.

Cada decisão vai para o registro de decisões, no mesmo formato. Para a manhã de quinta:

| hora | ação | proposta por | decidida por | por quê | desfeita por |
|---|---|---|---|---|---|
| 09:31 | estado volátil do `gw` e do `files` coletado, com hash | ana | ana | antes de qualquer mudança | (nada a desfazer) |
| 09:38 | regra de saída no `fw`: `files` só para o backup | ana | ana | dados saíram para `203.0.113.200` | regra `INC-2026-014 files egress`, pelo handle |
| 09:40 | bloqueio de `203.0.113.66` no `fw` | diego | ana | barato; atrasa a nova tentativa óbvia | regra `INC-2026-014 source`, pelo handle |
| 09:45 | conta do bruno bloqueada no `gw` e no `files`; sessões encerradas | ana | sócia-diretora | senha roubada e uma chave adicionada | credenciais novas, entregues ao bruno pessoalmente |

A sócia-diretora assina a última linha porque ela impede um funcionário de trabalhar, e porque o bruno precisa
ser avisado pessoalmente, por alguém que não seja investigador, que é a aula 19. As duas regras de firewall são
decisão da ana: não quebram nada que o negócio usa. **O registro não precisa ser elaborado; precisa existir na
hora**, escrito enquanto as coisas acontecem. Reconstruído depois, de memória, é a primeira coisa em que um
advogado ou um regulador aprende a desconfiar.
