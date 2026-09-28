---
title: Escolhendo uma
version: 1
---

Três licenças cobrem quase todo projeto de portfólio, e a diferença entre elas é uma pergunta: **o que
alguém precisa fazer se usar o seu código no dele?**

| licença | pode | precisa | motivo típico para escolher |
|---|---|---|---|
| MIT | usar, mudar, vender, manter fechadas as mudanças | manter o seu aviso de copyright e o texto da licença | a licença permissiva mais curta e conhecida |
| Apache 2.0 | o mesmo que a MIT | o mesmo, mais indicar as mudanças; também concede licença de patentes | uma licença permissiva com termos de patente explícitos |
| GPL 3.0 | usar e mudar | publicar o programa inteiro sob a GPL se o distribuir | você quer que toda obra derivada continue aberta |

O loanbook usa **MIT**, e num projeto de portfólio essa costuma ser a escolha sem surpresa: não pede nada a
quem avalia e quer experimentar, a uma escola que quer rodar, ou a um futuro empregador que quer ver. A
Apache 2.0 é igualmente boa. A GPL é uma posição real com bons motivos por trás, e escolhê-la é uma decisão
que você deve estar pronto para explicar, aula 20.

Confira mais uma coisa: **as licenças do que você usa.** O loanbook depende só da biblioteca padrão do Python,
sob a licença da Python Software Foundation, que é permissiva. Um projeto que usa uma biblioteca GPL e se
distribui sob MIT tem um problema que vale encontrar antes de quem avalia. Os gerenciadores de pacotes listam
a licença de cada dependência; leia a lista uma vez.
