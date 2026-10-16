---
title: O que dizer ao cliente
version: 1
---

Tudo até aqui aconteceu nos sistemas. A pessoa na frente da tela não vê nada disso: vê um número, um
botão, e se os dois fazem sentido juntos. **Um sistema eventualmente consistente é julgado pelas telas**,
e alguns hábitos decidem se as janelas dele parecem defeitos.

- **Depois de uma escrita, mostre a resposta da escrita.** O checkout devolve o pedido que criou; a
  página seguinte mostra esse pedido, e não uma lista lida de volta de uma cópia que talvez ainda não o
  tenha. É o ler as próprias escritas mais barato que existe.
- **Não ponha duas cópias numa tela.** Um cabeçalho dizendo "3 itens na sua cesta" a partir de uma cópia
  e uma página da cesta listando dois a partir de outra é a discordância tornada visível. Uma tela, uma
  fonte.
- **Diga quando um número é aproximado.** "Restam poucos" em vez de "resta 1" quando o número vem de uma
  cópia, e a contagem exata no checkout, a partir do dono. A aula 8 pôs a contagem da prateleira do lado
  disponível por esse motivo.
- **Dê ao trabalho que acontece depois um estado próprio.** Um pedido está "recebido", depois
  "confirmado" quando pagamento e estoque responderam. Um reembolso está "solicitado", depois "feito".
  Quem vê "recebido" entende que alguma coisa ainda está acontecendo; quem não vê nada supõe que falhou.
- **Diga a idade de uma visão, onde a idade importa.** "Atualizado há 2 minutos" sobre um painel
  transforma um número velho de mentira em fato.

## O que não pode ser eventual

Algumas decisões não podem ser tomadas a partir de uma cópia, diga a tela o que disser. Pegar o último
pacote de café, cobrar um cartão e aceitar um preço acontecem **no dono**, onde a ordem das mudanças é
uma ordem só, como a tabela da aula 8 escolheu. Uma cópia pode dizer "resta 1"; o checkout pergunta ao
serviço de estoque, que pode dizer "esgotado", e essa é a resposta que vale. Quando a decisão atravessa
vários serviços, cada um com o seu dono, não há um lugar só para perguntar, e a aula 14 é sobre o que
fazer em vez disso.

Quando terminar a aula, pare os servidores dela:

```sh
docker compose down -v
```
