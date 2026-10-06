---
title: O time vermelho
version: 1
---

**O time vermelho faz o papel do atacante, com permissão.** O trabalho dele é descobrir o que um
adversário real conseguiria fazer, fazendo, sob regras, antes que alguém sem regras faça. Dois tipos de
trabalho vão sob esse nome, e muitas vezes são confundidos:

| | teste de invasão | exercício de time vermelho |
|---|---|---|
| **objetivo** | achar o máximo de fraquezas num escopo definido | testar se a organização detecta e responde a um ataque realista |
| **escopo** | estreito: uma aplicação, uma rede | amplo: o que um atacante real usaria, muitas vezes incluindo pessoas |
| **quem sabe** | os defensores em geral sabem que está acontecendo | o mínimo de gente possível, para a resposta ser real |
| **duração** | de dias a algumas semanas | de semanas a meses |
| **resultado** | uma lista de vulnerabilidades para corrigir | uma história do que aconteceu e de onde a detecção falhou |

Um teste de invasão pergunta "onde estão os furos?". Um exercício de time vermelho pergunta "se alguém
entrasse por um deles, perceberíamos, e o que faríamos?". Os dois são úteis, e uma loja pequena precisa
do primeiro muito antes do segundo.

### As regras são o que o torna legítimo

O que separa um time vermelho de um criminoso não é a técnica. É a **autorização por escrito** e as
**regras de engajamento**, combinadas antes de qualquer coisa começar:

- o **escopo**: quais sistemas, quais endereços, quais pessoas podem ser alvo, e quais não;
- a **janela**: quando o teste acontece;
- os **limites**: o que fica de fora mesmo dentro do escopo, como apagar dados ou atrapalhar as vendas
  da loja;
- um **contato de emergência** de cada lado, e um jeito de parar tudo de uma vez;
- o que acontece com qualquer dado real que os testadores virem.

Testar um sistema que não é seu, ou que você não recebeu permissão por escrito para testar, é crime no
Brasil como na maioria dos países, qualquer que seja a intenção. As aulas 1, 2 e 22 de `pentest` tratam
em detalhe das regras, do documento de autorização e dos limites legais, e elas vêm antes de qualquer
técnica naquele curso por um motivo.

Pelo mesmo motivo, tudo o que este curso mostra é feito no laboratório dele, contra máquinas que o
curso montou para isso. O lado vermelho no exercício desta aula é a ana, testando o portal da própria
loja, combinado antes com os sócios.
