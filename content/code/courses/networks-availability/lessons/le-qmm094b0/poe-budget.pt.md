---
title: Power over Ethernet, o orçamento que ninguém soma
version: 1
---

Um AP corporativo tira a energia da porta do switch, pelo mesmo cabo dos dados: Power over Ethernet, da
aula 21 de `networks-addressing`. As normas definem o que uma porta de switch fornece e o que chega ao
aparelho depois da perda no cabo:

| norma | na porta do switch | no aparelho |
|---|---|---|
| 802.3af (PoE) | 15,4 W | 12,95 W |
| 802.3at (PoE+) | 30 W | 25,5 W |
| 802.3bt tipo 3 | 60 W | 51 W |
| 802.3bt tipo 4 | 90 W | 71,3 W |

Dois números decidem se um projeto funciona, e nenhum deles é o da frente da caixa.

**Do que o AP precisa.** Muitos APs atuais, com vários rádios e vários fluxos espaciais cada, precisam de
802.3at ou 802.3bt para rodar tudo. Com menos energia, boa parte deles não se recusa a ligar: **eles
ligam e rodam com um rádio ou alguns fluxos desligados**, e dizem isso numa linha de log. A rede
funciona, com menos capacidade que a projetada, e nada na superfície diz por quê. Esse é o tipo de falha
silenciosa que o status de energia do AP no switch existe para pegar.

**O que o switch consegue fornecer no total.** Um switch de 24 portas com PoE em todas elas não tem
24 × 30 W para dar. O **orçamento de PoE** dele é um número separado no datasheet, muitas vezes bem menor
que portas vezes o máximo. Como ele é gasto depende do switch. Alguns reservam energia por classe, os 30 W
inteiros para qualquer aparelho 802.3at, consuma ele ou não; outros alocam o que o aparelho pede por LLDP,
ou o que ele consome. Planejar com a reserva por classe é a suposição segura.

Um caso calculado: um switch, dezesseis APs que precisam de 802.3at e seis câmeras em 802.3af:

```schooling-example
{"language": "python", "file": "poe.py", "parts": [{"code": "budget_w = 370                  # the switch's PoE budget, from its data sheet\nreserve_w = {\"802.3af\": 15.4, \"802.3at\": 30.0, \"802.3bt type 3\": 60.0}", "note": "O total do switch, e o que uma porta reserva por norma quando o switch aloca por classe: a potência na porta do switch, antes da perda no cabo. 370 W é um valor de exemplo para um switch de 24 portas, não uma norma."}, {"code": "aps, cameras = 16, 6\nneed = aps * reserve_w[\"802.3at\"] + cameras * reserve_w[\"802.3af\"]\nprint(f\"reserved: {aps} x 30.0 + {cameras} x 15.4 = {need:.1f} W of {budget_w} W\")\nprint(f\"short by {need - budget_w:.1f} W\")", "note": "Dezesseis pontos de acesso que precisam de 802.3at, e seis câmeras em 802.3af, todos num switch só."}, {"code": "fits = int((budget_w - cameras * reserve_w[\"802.3af\"]) // reserve_w[\"802.3at\"])\nprint(f\"802.3at access points that fit beside the cameras: {fits}\")", "note": "O que cabe, depois que as câmeras levam a parte delas."}], "output": "reserved: 16 x 30.0 + 6 x 15.4 = 572.4 W of 370 W\nshort by 202.4 W\n802.3at access points that fit beside the cameras: 9"}
```

**572,4 W reservados contra um orçamento de 370 W.** O switch liga as portas na ordem de prioridade dele
até o orçamento acabar, e as demais ficam sem energia. Com as câmeras atendidas, **cabem nove APs**. As
correções são um switch com orçamento maior, um segundo switch, ou APs distribuídos pelos switches que o
projeto já tem.

## Distribua de qualquer jeito

Mesmo quando o orçamento fecha, pôr todos os APs de um andar num switch só faz dele um ponto único de
falha para toda a rede sem fio do andar. **Alterne APs vizinhos entre dois switches**, e um switch que
falhar deixa todas as outras células funcionando e a cobertura irregular em vez de ausente, que é o
raciocínio de redundância da aula 14 aplicado a um forro.
