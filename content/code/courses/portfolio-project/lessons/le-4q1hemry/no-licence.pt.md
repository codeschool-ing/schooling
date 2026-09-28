---
title: O que a falta de licença quer dizer
version: 1
---

Um repositório público sem arquivo de licença **não** é livre para outros usarem. Pela lei de direito
autoral da maioria dos países, inclusive a do Brasil, quem criou tem os direitos por padrão, e mais ninguém
pode copiar, modificar ou distribuir a obra sem permissão. Os sites de hospedagem acrescentam pouco: os
termos do GitHub deixam outros verem e fazerem fork de um repositório público no próprio GitHub. Nada além.

Num portfólio isso importa menos pelo que desconhecidos podem fazer do que pelo que sinaliza. Quem avalia e
não encontra licença vê alguém que não pensou em como o próprio trabalho pode ser usado, que é o tipo de
pergunta que projetos de verdade respondem no primeiro dia. A correção é um arquivo e um commit:

```
ana@laptop:~/loanbook$ head -3 LICENSE
MIT License

Copyright (c) 2026 Ana Lima
ana@laptop:~/loanbook$ git show --stat --format=%s HEAD
License under MIT

 LICENSE | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)
```

`LICENSE`, na raiz, com o texto inteiro de uma licença padrão, o ano e o nome de quem detém os direitos. O
GitHub e o GitLab reconhecem as licenças comuns por esse arquivo e mostram o nome na página inicial do
repositório, então quem lê não precisa abri-lo. A última seção do README diz o mesmo numa linha, aula 16.

Duas coisas para nunca fazer. **Não escreva a sua própria licença**: um texto próprio é algo que ninguém
consegue interpretar sem um advogado, inclusive você. E **não copie a licença de um projeto esquecendo de
trocar o nome**: *Copyright (c) outra pessoa* no seu projeto é a afirmação de que ele é dela.
