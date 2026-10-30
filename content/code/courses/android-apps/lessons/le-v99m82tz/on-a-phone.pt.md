---
title: O que só um celular mostra
version: 1
---

**A caixa de diálogo é do sistema, e tudo em volta dela também.** Esta seção descreve o que um
estudante encontra num celular de verdade e o que um app deve esperar. **Não executado**: nenhum
aparelho ou emulador estava disponível quando o curso foi gravado, como a seção 02 da aula 1 explica,
e tudo abaixo vem da documentação do Google sobre permissões de execução, lida em 30 de outubro de
2026.

## A caixa de diálogo

O sistema a desenha por cima do app, com o nome do app e os botões daquela permissão. Para
`POST_NOTIFICATIONS` eles são *Permitir* e *Não permitir*. O app não pode mudar o texto, acrescentar
uma explicação dentro dela nem estilizá-la; a explicação pertence ao app, antes do pedido, que é para
o que serve o segundo cartão da seção 05. Tocar fora da caixa a dispensa sem resposta, e isso não
conta como recusa.

## Permissões que concedem menos do que parece

Algumas permissões de execução têm respostas intermediárias que o planner não encontra, mas outros
apps encontram:

- **Localização** pode ser concedida como *aproximada* em vez de *precisa*, e *só durante o uso do
  app* em vez de o tempo todo. Um app que pede localização precisa recebe a aproximada se foi essa a
  escolha do estudante, e precisa trabalhar com ela.
- **Câmera, microfone e localização** podem ser concedidos *só desta vez*: a permissão dura enquanto
  o app está em uso e é retirada pouco depois de ele sair da tela.
- **Apps sem uso** têm as permissões de execução zeradas pelo Android depois de alguns meses sem
  serem abertos, então uma permissão concedida no ano passado não é uma permissão que o app tem hoje.

Cada uma delas é mais um motivo para conferir antes de cada uso, e não uma vez só.

## Concedendo e revogando pelo terminal

Com um celular ou um emulador conectado, a documentação do Google mostra como pôr uma permissão num
estado conhecido sem a caixa, que é como testes instrumentados e conferências manuais chegam a cada
linha da seção 04:

```sh
adb shell pm grant com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm revoke com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm clear-permission-flags com.example.planner android.permission.POST_NOTIFICATIONS user-set user-fixed
```

O terceiro comando limpa as marcas que registram as recusas do estudante, o que devolve a permissão a
"nunca pedida" para testar. **Não executado**, como o resto desta seção, então não há saída.

## A loja também opina

O Google Play pede que um app declare por que usa algumas permissões, e revisa apps que pedem as
sensíveis. A aula 13 de `mobile-fundamentals` trata do que a loja obriga a declarar, e a aula 22
deste curso chega ao Play Console. Uma permissão de que o app não precisa é uma pergunta na revisão e
um motivo para o estudante hesitar, então a permissão mais barata é a que o planner nunca declara.
