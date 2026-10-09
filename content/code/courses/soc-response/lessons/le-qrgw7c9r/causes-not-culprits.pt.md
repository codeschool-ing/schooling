---
title: Causas, não culpados
version: 1
---

A quinta tem uma candidata óbvia à culpa: a senha do bruno era fraca o bastante para ser adivinhada. Uma
revisão que para aí escreve "o bruno vai escolher uma senha melhor" como ação, e não muda mais nada. A próxima
senha fraca, na próxima conta, funciona do mesmo jeito.

Uma revisão **sem culpa** supõe que todo mundo agiu de forma razoável com o que sabia na hora, e pergunta o que
no *sistema* deixou uma ação razoável levar a um dano. Não é gentileza. É precisão, e é como a revisão chega
à verdade: quem espera ser culpado descreve o que deveria ter feito, e quem não espera descreve o que fez.

A diferença aparece no jeito de escrever um achado:

| com culpa | sem culpa |
|---|---|
| o bruno escolheu uma senha fraca | o `gw` aceitava senhas da internet inteira, sem limite de tentativas |
| ninguém viu o alerta por cinco horas | alertas críticos iam para uma fila que ninguém olhava à noite |
| o servidor de arquivos mandou 612 MB para fora | o `files` conseguia alcançar qualquer endereço da internet |
| ninguém percebeu a chave nova | não havia inventário de chaves para comparar |

Cada frase da direita é um **fator contribuinte**: algo que, se fosse diferente, teria impedido o incidente ou
o encurtado. Raramente há uma única causa raiz. A quinta precisou dos quatro: uma senha que dava para
adivinhar, *e* um servidor que deixou tentar 57 vezes, *e* um servidor de arquivos que mandava para qualquer
lugar, *e* um alerta que não chegou a ninguém. Tirar qualquer um deles teria mudado a noite.

Perguntar **"por quê?"** várias vezes é a ferramenta comum, e funciona enquanto cada resposta for sobre uma
condição, não sobre uma pessoa. Por que os palpites funcionaram? Porque senhas eram aceitas da internet. Por
que eram? Porque o `gw` foi instalado com a configuração padrão, e ninguém tinha decidido outra coisa. Por que
não? Porque não havia um padrão de instalação para servidores. Essa última resposta é a que vale uma ação: é
por isso que o conserto da aula 14 precisou ir para um padrão.
