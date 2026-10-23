---
title: A tabela de estados, ou como uma máquina de estados acha bugs
version: 1
---

**Uma máquina de estados desenhada mostra as transições em que alguém pensou; a mesma máquina escrita
como tabela mostra aquelas em que ninguém pensou.** Ponha os estados de um lado e os eventos no topo,
e cada célula tem de ser preenchida. Uma célula em branco é uma pergunta que o design ainda não
respondeu.

## A passagem da Carcará, como tabela

| estado ↓ · evento → | pagamento aprovado | pagamento recusado | passam 10 min | cancelada | lida | partiu |
| --- | --- | --- | --- | --- | --- | --- |
| **Reservada** | → Paga | continua Reservada | → Expirada | → Expirada, libera assento | recusa | → Expirada |
| **Paga** | ? | ? | ignora | ≥ 3 h: → Estornada; < 3 h: recusa | → Embarcada | → Não embarcou |
| **Expirada** | **?** | ignora | ignora | ignora | recusa | ignora |
| **Embarcada** | ? | ? | ignora | recusa | recusa: já usada | ignora |
| **Estornada** | ? | ? | ignora | ignora | recusa | ignora |
| **Não embarcou** | ? | ? | ignora | recusa | recusa | ignora |

Trinta e seis células, e o diagrama da seção anterior tinha sete transições. A maioria das células a
mais é *ignora* ou *recusa*, o que está ótimo, mas cada uma agora é uma decisão escrita e não um
acidente do que o código por acaso fizer.

## A célula que importava

**Expirada × pagamento aprovado.** O passageiro aperta *pagar* no minuto nove; a rede do cartão leva
noventa segundos; o timer dispara no minuto dez, a passagem expira e libera o assento; no minuto dez
e meio chega o webhook do gateway de pagamento dizendo *aprovado*. O diagrama de sequência da aula 2
mostrou que o webhook pode chegar atrasado. A máquina de estados não tinha seta para isso, e a tabela
torna a ausência impossível de não ver.

O código da Carcará na época fez o que o código faz quando ninguém decidiu: marcou a reserva expirada
como paga, e o assento, já liberado, tinha sido vendido para outra pessoa. Dois passageiros, um
assento, na sexta-feira antes do São João. A decisão que Tainá escreveu na tabela depois:

> **Expirada × pagamento aprovado**: estornar o pagamento automaticamente, manter a passagem Expirada
> e avisar o passageiro de que o assento foi liberado, com os assentos livres mais próximos na mesma
> viagem.

Essa decisão virou uma transição no diagrama, um teste no código e, na aula 5, um registro de decisão.

## Eventos repetidos

A outra pergunta que as linhas levantam é **e se o mesmo evento chegar duas vezes?** Gateways
reenviam webhooks, e celulares reenviam leituras quando o sinal cai. *Paga × pagamento aprovado*
deveria ser *ignora*, não um erro e nem uma segunda cobrança registrada. *Embarcada × lida* deveria
ser *recusa, já usada* na porta e *ignora* quando o mesmo celular reenvia o upload. A aula 2 chamou
isso de idempotência; a tabela de estados é onde você decide isso estado por estado.

**Desenhe você.** Preencha os pontos de interrogação da tabela acima. Para cada um, escreva a decisão
e uma frase dizendo por quê. Depois compare com a decisão de *Expirada × pagamento aprovado*: o mesmo
raciocínio resolve a maior parte das outras.
