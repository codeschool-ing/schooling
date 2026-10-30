---
title: Excluir a conta, de dentro do app
version: 1
---

**Um app que deixa as pessoas criarem uma conta tem de deixá-las excluí-la, e as duas lojas agora
conferem.** A diretriz 5.1.1(v) da Apple diz isso numa frase: *se o seu app permite criar conta,
ele também precisa oferecer a exclusão da conta dentro do app.* O Google Play pergunta o mesmo no
formulário de Segurança dos dados, e também pede um **endereço web** onde alguém possa pedir a
exclusão sem instalar o app, para a pessoa que já o desinstalou.

## O que "excluir" precisa significar

- **Dentro do app, fácil de achar.** Uma tela de configurações, a poucos toques do início; não um
  endereço de e-mail nas letras miúdas, e não "fale com o suporte".
- **A conta e os dados dela, e não uma desativação.** Esconder uma conta e manter tudo não é
  excluir. O que a lei exige guardar, uma nota fiscal por exemplo, é guardado, e a pessoa é avisada
  do que e por quanto tempo.
- **Dito com clareza antes de acontecer, e feito depois.** Uma confirmação, uma frase dizendo o que
  vai embora, e então vai. Se a exclusão leva dias no servidor, a pessoa é avisada disso.

## Para o planner

A conta do planner guarda um e-mail e as sessões sincronizadas no servidor. Excluí-la remove os
dois do servidor e desconecta o celular. As sessões no próprio celular são da pessoa, para manter
ou apagar; o app pergunta qual. E o inventário da seção "O inventário" responde à pergunta do
Google com `"deletionOnRequest": true` só depois que a página web existe.

## As outras duas plataformas

Isso é trabalho do servidor, e não da plataforma: um endpoint exclui a conta, e cada cliente,
Kotlin, Swift ou React Native, tem uma tela que o chama. A regra é a mesma nas duas lojas, então o
trabalho é feito uma vez.
