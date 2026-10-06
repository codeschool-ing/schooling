---
title: Instruções e dados
version: 1
---

Todo prompt deste curso teve dois tipos de texto. **Instruções**, que a equipe escreveu: o prompt de
sistema da aula 7, o que citar, quando recusar. E **dados**, que vieram de outro lugar: as políticas, a
mensagem de um cliente, um turno lembrado, um resumo. O programa sempre soube qual era qual, porque pôs
cada um no seu lugar.

O modelo não sabe. Ele recebe uma sequência de tokens, e nada nessa sequência vem marcado como
"obedeça isto" ou "só leia isto" de um jeito que o modelo seja obrigado a respeitar. Uma mensagem de
sistema é uma dica forte, e os modelos são treinados para dar peso a ela; não é um muro. Então qualquer
texto que chega ao prompt pode, em princípio, funcionar como instrução, e **a pergunta que todo
pipeline precisa responder é de onde vem o seu texto e quem poderia tê-lo escrito**.

Para os documentos deste curso a resposta era confortável: a Marginalia os escreveu. Assim que um
pipeline lê texto escrito por outra pessoa, está lendo texto que outra pessoa escolheu:

- **clientes**, em toda mensagem a um chat de atendimento;
- **vendedores**, nos anúncios e descrições de um marketplace;
- **a web**, numa página que um agente buscou;
- **outros sistemas**, num e-mail, num chamado, num arquivo enviado para resumir, na saída de uma
  ferramenta.

Texto posto ali para mudar o que um modelo faz se chama **injeção de prompt**. Esta aula a trata como um
defensor trata qualquer entrada não confiável: mostrar que a fraqueza existe com algo inofensivo, depois
construir as camadas que a impedem de importar, e testar cada uma. O exemplo é um canário, uma frase
pedindo a palavra PINEAPPLE, escolhida porque uma palavra não consegue fazer nada e um teste vê na hora
se ela foi obedecida.
