---
title: Um furo na parede, de propósito
version: 1
---

Um convidado é útil porque fica murado do host: a aula 1 apagou o sistema inteiro de um convidado e o
host nem percebeu. **Uma pasta compartilhada com escrita é uma porta nesse muro.** O que roda no
convidado pode criar, mudar e apagar arquivos nela, e eles são arquivos do host:

- Um convidado infectado por ransomware cifra todo arquivo em que consegue escrever, **a pasta
  compartilhada inclusive**.
- Um teste que dá errado e apaga o conteúdo de uma pasta apaga a cópia do host, porque só existe uma
  cópia.
- Um convidado em que você não confia, como o alvo da aula 14, pode deixar algo na pasta para o host
  abrir depois.

Então compartilhe o que o convidado precisa e nada mais, **só de leitura sempre que o convidado só
precisar ler**, como era a `docs`, e nunca compartilhe uma pasta pessoal inteira ou um disco. Um convidado
que vai rodar algo hostil não recebe pasta compartilhada nenhuma, aula 15, e os arquivos chegam a ele
pelo caminho longo, pela rede, um de cada vez.
