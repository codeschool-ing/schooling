---
title: Cinco títulos numa página
version: 1
---

A imagem comum de uma estratégia séria é um documento longo: uma análise de mercado, uma revisão de
arquitetura, a história de como a empresa chegou até aqui, e um apêndice com as propostas de cada
time. Parece completo. **O tamanho é onde a escolha se esconde.** Quem precisa atravessar tudo isso
para achar o que a empresa decidiu quase nunca acha, e as pessoas que mais precisam saber são as que
menos chegam tão longe.

Uma estratégia que um time consegue usar cabe numa página, com cinco títulos:

| título | o que diz | de onde vem |
|---|---|---|
| Diagnóstico | o que está acontecendo, e que parte disso importa | o núcleo, aula 1 |
| Política orientadora | a abordagem, numa frase que alguém consegue repetir | o núcleo, aula 1 |
| O que vamos fazer | as ações, cada uma com dono e início | o núcleo, aula 1 |
| O que não vamos fazer | as propostas que a política exclui, pelo nome | a próxima seção |
| Como vamos saber | os sinais que mostrariam que está funcionando, ou falhando | esta seção |

Os três primeiros são o núcleo de Rumelt. Os dois últimos são o que torna a página útil numa
terça-feira qualquer, para alguém decidindo se o seu próximo trabalho se encaixa.

## Um one-pager, e o que é particular deste

O documento de uma página como gênero — para quem é, como se estrutura, como cortar até caber — é a
aula 2 do curso `architect-communication`. Tudo o que está lá vale aqui. Uma página de estratégia
difere de uma página de proposta em alguns pontos, e são eles que decidem como ela é escrita.

**Uma proposta pede uma decisão. Uma página de estratégia é ferramenta para centenas de decisões
posteriores.** A proposta é lida uma vez, por quem a aprova. A estratégia é consultada de novo e de
novo, por gente que não estava na sala, na hora de decidir algo que a página nunca mencionou. Então
ela é escrita para a engenheira da Bilheteria que quer saber se a sua mudança no mapa de assentos
pode sair na semana que vem, e não para a Helena, que já concordou com ela.

Ela leva um cabeçalho de que uma proposta não precisa: **quem é dono, quem assinou e quando será a
próxima revisão.** A página vai ser citada em discussões, e uma citação precisa de uma fonte com
data. Ela também deixa a evidência de fora. A análise de incidentes que sustenta o diagnóstico é um
link, não um parágrafo, porque quem lê a página precisa da conclusão, e quem revisa a evidência sabe
onde procurar.

## A página do Davi

Davi escreveu a página como um arquivo Markdown num editor de texto puro, a ferramenta que a aula 1
preparou, e a pôs no manual de engenharia ao lado dos relatórios de incidente que ela cita. Esta é a
versão que saiu depois do teste da terceira seção desta aula:

> **Estratégia técnica da Coreto: proteger a abertura de vendas primeiro**
>
> Dono: Davi Moreira · Assinada por: Helena Prates, CTO · Próxima revisão: fim de cada trimestre
>
> **Diagnóstico.** A Coreto ganha sua reputação em umas doze grandes aberturas de vendas por ano, e
> é exatamente nelas que falha. As falhas vêm do código de reserva de assentos no módulo de
> reservas, que todos os times mudam e nenhum time possui. Todo o resto nas listas dos times é
> real, e nada disso nos custa uma casa de shows como uma abertura que falha.
>
> **Política orientadora.** Proteger a abertura de vendas primeiro. O trabalho no caminho da
> reserva de assentos vem antes de qualquer outro investimento técnico, e nada entra nele sem
> evidência de um teste de carga.
>
> **O que vamos fazer.**
>
> 1. A partir de 1º de março, um time de Reservas com quatro pessoas, vindas de Checkout e
>    Pagamentos, é dono do módulo de reservas. Mudanças no código de reserva de assentos precisam da
>    revisão dele.
> 2. A Plataforma constrói um teste de carga que reproduz uma abertura, antes que alguém mude o
>    caminho da reserva.
> 3. Reservas passa seus dois primeiros trimestres tirando as travas de linha do caminho da
>    reserva, medido pelo teste de carga.
> 4. Nenhum deploy no módulo de reservas nas 24 horas antes de uma grande abertura.
>
> **O que não vamos fazer este ano.**
>
> - Começar a migração para microsserviços, nem mesmo um serviço de cada vez.
> - Mudar para um novo framework de front-end.
> - Reescrever o módulo de reservas do zero.
> - Mudar o caminho de reservas na temporada de aberturas por custo ou por funcionalidade, a menos
>   que a mudança tenha passado no teste de carga.
>
> **Como vamos saber.**
>
> - Toda grande abertura deste ano termina sem um incidente de checkout atribuído às reservas de
>   assento.
> - A disponibilidade do checkout nos dias de abertura chega a 99,99%.
> - Toda mudança no caminho da reserva leva o resultado do seu teste de carga.
> - Até o fim do segundo trimestre do time de Reservas, o caminho da reserva não usa mais travas de
>   linha.

A política está no título. Não era assim na primeira versão, e a terceira seção explica por que ela
mudou de lugar.

## Como vamos saber

O último título é o que mais se deixa de fora, e o que mantém a página honesta. **Cada linha dele
precisa poder dar errado.** "Os times se sentem mais confiantes com as aberturas" não tem como ser
falso: sempre há alguém que se sente melhor. "Toda grande abertura termina sem um incidente de
checkout atribuído às reservas de assento" pode ser falso numa terça às 10h05, e todo mundo vai
saber.

Os quatro sinais da página do Davi são de dois tipos, e uma página precisa dos dois. Dois são
**resultados**: as aberturas terminam bem, e a disponibilidade nos dias de abertura chega ao alvo que
a aula 1 rebaixou de meta a medida. Dois são **evidência de que as ações estão acontecendo**:
resultados do teste de carga em toda mudança, e as travas de linha eliminadas até uma data. Os
resultados dizem se a estratégia está certa. A evidência diz se alguém a está executando, e chega
meses antes de os resultados poderem chegar.

Um sinal que mede atividade e não efeito — tickets fechados, reuniões feitas, um documento
publicado — não entra na lista, porque pode ficar verde enquanto as aberturas continuam falhando.

## Se não couber

Quando um rascunho passa de uma página, a causa quase sempre está antes da escrita. Um diagnóstico
que cobre três problemas produz três políticas e uma página de ações; uma política que não exclui
nada produz uma lista do que não fazer vazia, e o espaço se enche de contexto. **Corte o diagnóstico
até o único desafio que importa, e o resto da página costuma vir junto.**

Experimente na sua própria organização antes de continuar. Abra um arquivo Markdown novo, escreva os
cinco títulos e preencha cada um com o que é verdade onde você trabalha hoje. O título que você não
consegue preencher é a parte da sua estratégia que ainda não existe.
