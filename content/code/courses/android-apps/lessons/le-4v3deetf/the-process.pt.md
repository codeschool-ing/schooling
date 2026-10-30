---
title: O processo, e o dia em que o sistema o tira de você
version: 1
---

**Um app Android é um processo Linux, e o sistema o mata sempre que precisa da memória.** Não quando
o app quebra, não quando o usuário o fecha: quando um celular com quatro apps abertos quer espaço
para um quinto, os que estão em segundo plano vão embora, e ninguém pergunta aos donos deles. As
aulas 4 e 5 de `mobile-fundamentals` descrevem isso para as duas plataformas; esta seção é o que
isso significa para uma activity.

Todo app começa do mesmo jeito. O Android mantém um processo rodando desde a inicialização, chamado
**zygote**, com as classes do framework já carregadas, e o processo de um app novo é uma cópia dele
feita com `fork`. É por isso que um app abre numa fração de segundo apesar de o framework ser
grande. O processo novo então cria o objeto `Application`, depois a activity que o usuário pediu.

## A morte do processo, passo a passo

**Não executado.** Nada disto pode ser mostrado num computador sem aparelho: o Robolectric roda
dentro da JVM do teste, e esse processo não é morto. O que vem a seguir é a sequência que a
documentação do Google sobre o ciclo de vida da activity e sobre estado salvo descreve, e a que a
aula 5 de `mobile-fundamentals` desenha.

1. O usuário abre o planner, vai até um curso e aperta o Home. A activity para e o
   `onSaveInstanceState` escreve o `Bundle` dela, a chamada que a rotação da seção 04 mostrou.
2. Algum tempo depois o sistema precisa de memória e mata o processo do planner. **Nenhum callback
   roda**: nem `onDestroy`, nem nada. O processo simplesmente some, e cada objeto dele junto.
3. O sistema guarda duas coisas: a tarefa, que lembra quais activities estavam na tela, e os
   `Bundle`s salvos delas.
4. O usuário toca no planner na lista de apps recentes. Um processo novo é criado por `fork`,
   `ProcessWide.created` recomeça do 0, e a activity é criada com o `Bundle` antigo:
   `saved state: true`, num processo que nunca viu essa activity antes.

O usuário vê a tela que deixou. **Esse é o propósito todo, e ele falha em silêncio** quando a tela
dependia de algo que vivia só na memória: uma lista carregada num campo, um valor num `object`, um
cache. No celular de quem testa o app, com memória de sobra, isso nunca acontece; no celular de um
estudante com um aparelho barato e vinte apps abertos, acontece todo dia.

Num aparelho, a documentação do Google reproduz isso com o app em segundo plano e
`adb shell am kill com.example.planner`, que mata o processo do jeito que o sistema mataria. As
opções de desenvolvedor também têm um ajuste, *Não manter atividades*, que destrói cada activity
assim que ela para. **Não executado** aqui.

## O que sobrevive a quê

| onde um valor mora | rotação | Home, e depois volta | morte do processo | o usuário arrasta o app para fora |
|---|---|---|---|---|
| um campo da activity | perdido | mantido | perdido | perdido |
| o `Bundle` salvo | mantido | mantido | mantido | perdido |
| um `object`, ou um `ViewModel` | mantido | mantido | perdido | perdido |
| um arquivo ou um banco de dados | mantido | mantido | mantido | mantido |

**Só a última linha sobrevive a tudo**, e é por isso que a aula 15 põe as sessões do planner num
banco de dados. O `Bundle` é para as coisas pequenas que descrevem onde o usuário estava, um curso
aberto ou um nome digitado pela metade. Ele tem limite de tamanho: a documentação do Google recomenda
manter o estado salvo abaixo de 50 kB, porque ele viaja entre processos e uma transação grande
demais lança `TransactionTooLargeException`. Arrastar o app para fora da lista de recentes é o
usuário dizendo que terminou, e até o `Bundle` vai junto.
