---
title: O número maior
version: 1
---

O IPv6 é a resposta ao IPv4 ter acabado, e a resposta é simplesmente **mais bits**: 128 deles em
vez de 32.

Isso soa como quatro vezes mais endereços. Não é. Cada bit dobra a conta, então 128 bits são 2⁹⁶
vezes mais — um número de trinta e nove dígitos, grande o bastante para a questão de acabar não
voltar.

## Ler um sem pânico

Um endereço IPv6 são oito grupos de quatro dígitos hexadecimais, separados por dois-pontos:

`2001:0db8:0000:0000:0000:ff00:0042:8329`

Isso é ilegível, e duas regras encurtam. **Zeros à esquerda de um grupo são descartados**, e **uma
sequência de grupos todos zero é substituída por `::`**. Aplicando as duas:

`2001:db8::ff00:42:8329`

O `::` pode aparecer uma vez só num endereço, porque dois seriam ambíguos — nada poderia dizer
quantos grupos zero pertencem a cada um.

O hexadecimal está aí porque 128 bits em decimal seriam ainda mais longos, e porque quatro dígitos
hex são exatamente dezesseis bits, então cada grupo é uma fatia limpa em vez de arbitrária.

## Três que você vai reconhecer

`::1` é o loopback — o `127.0.0.1` do IPv6, e a regra de encurtamento no extremo.

Qualquer coisa começando com `fe80:` é **link-local**: válido só neste fio, gerado pela própria
máquina sem pedir a ninguém, e nunca roteado. Toda interface IPv6 tem um, sempre, e muito
maquinário local roda sobre eles.

Qualquer coisa começando com `2` ou `3` costuma ser um endereço **global** — um endereço real,
roteável e único. Que é a parte que vale uma pausa.

## Sem endereços privados, e o que isso muda

No IPv6 há endereços suficientes para todo aparelho ter um globalmente único. Um telefone, um
notebook, uma lâmpada — cada um com o próprio endereço público, sem compartilhar.

Isso remove a razão de o NAT existir, e o NAT é o assunto do vídeo no fim desta aula. Remove
também algo que as pessoas tinham parado de notar que o NAT fazia: **recusar acidentalmente toda
conexão de fora**. Um aparelho com endereço público é um aparelho que a internet consegue endereçar
diretamente, e o que impede uma conexão passa a ser um firewall que alguém configurou de propósito,
em vez de uma tabela sem linha.

Isso é engenharia melhor e é outra postura de segurança, e surpreende quem estava contando com um
acidente.

## O que mais ele mudou enquanto ninguém olhava

O IPv6 costuma ser descrito como "IPv4 com mais bits", e o endereço é a parte visível. Três outras
mudanças valem conhecer porque aparecem na prática.

**Uma máquina consegue se endereçar sozinha.** Uma interface IPv6 monta o próprio endereço
link-local sem pedir a ninguém — sem servidor, sem negociação, sem modo de falha. Duas máquinas
ligadas uma na outra falam na hora. No IPv4 esse caso precisa do `169.254` que você vai encontrar
daqui a duas seções, que existe justamente porque o caminho comum falhou.

**Roteadores não fragmentam.** O problema de MTU da aula dois é tratado só nas pontas: um roteador
que não consegue passar um pacote o recusa e avisa, e nunca corta. Isso torna a mensagem de "grande
demais" da aula dois estrutural em vez de opcional — e torna a falha do buraco negro, onde essa
mensagem é descartada, correspondentemente pior.

**O cabeçalho é mais simples.** Menos campos, tamanho fixo, sem soma de verificação — porque as
camadas de baixo e de cima já conferem, e fazer três vezes era pagar pela mesma garantia duas vezes.

Nada disso é por que o IPv6 existe. Tudo isso é por que quem aprendeu IPv4 não simplesmente sabe
IPv6.

## Por que a troca leva trinta anos

O IPv6 ficou pronto em 1998. A adoção está em torno de metade do tráfego hoje, o que é uma lentidão
notável para algo sem concorrente sério.

O motivo é que **os dois não interoperam**. Uma máquina só-IPv6 não consegue falar com um servidor
só-IPv4 de jeito nenhum; os endereços não cabem no cabeçalho um do outro e não há tradução que seja
mera reescrita. Então ninguém pode trocar — todo mundo tem que rodar os dois enquanto alguém ainda
estiver no antigo, o que se chama pilha dupla, e é onde a maior parte da internet vive hoje.

Rodar os dois significa que toda máquina tem pelo menos dois endereços, todo nome pode resolver
para qualquer um dos dois, e todo diagnóstico tem que perguntar qual foi usado. Que é a
consequência prática para você: quando algo funciona para uma pessoa e não para outra, **qual
protocolo cada uma pegou** é uma pergunta que vale fazer cedo.

## Onde isto te deixa

O IPv6 são 128 bits escritos como oito grupos hexadecimais, encurtados descartando zeros à esquerda
e colapsando uma sequência de grupos zero em `::`. Há endereços suficientes para nada precisar ser
privado, o que remove o NAT e a proteção acidental que ele dava. Ele não interopera com o IPv4, que
é por que os dois rodam ao mesmo tempo e vão rodar por anos.

Tudo até aqui foi o endereço que atravessa o mundo. A próxima seção é o outro — o que não atravessa
nada.
