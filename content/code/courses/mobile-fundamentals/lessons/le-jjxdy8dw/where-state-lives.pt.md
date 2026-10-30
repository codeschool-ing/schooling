---
title: Três tipos de estado, e onde cada um mora
version: 1
---

**Uma tela guarda três tipos de estado, e cada um tem um lugar diferente para morar e um motivo
diferente para sobreviver.** O erro comum é tratá-los como um só: ou tudo é salvo, o que é lento e
enche o lugar feito para coisas pequenas, ou nada é, e o usuário perde o lugar onde estava toda vez
que o sistema tira o processo. Separá-los primeiro torna mecânico o resto desta aula.

| tipo | no planner | quanto tempo precisa durar | onde mora |
|---|---|---|---|
| **dados** | os cursos, as sessões, quais estão concluídas | até o usuário apagar | armazenamento persistente: um banco ou arquivos no aparelho |
| **estado de UI** | que curso está aberto, até onde a lista foi rolada, uma sessão meio digitada | até o usuário voltar a esta tela | estado salvo, guardado pelo sistema para o app |
| **efêmero** | uma onda sob o dedo, uma animação pela metade | nada; é redesenhado | só memória |

## Dados

**Dados são o que o usuário ficaria chateado de perder mesmo depois de fechar o app de propósito.**
Uma sessão que ele acrescentou, o fato de ela estar concluída, um curso em que ele se matriculou.
Eles pertencem ao disco do aparelho, num banco ou num arquivo, gravados quando mudam, e não na
saída, e lidos de novo a cada lançamento. Esse é o assunto da aula 16 deste curso, e o
`mobile-offline` passa vinte aulas nisso. Nesta aula o plano é uma constante no programa, no lugar
desse banco: ele sobrevive à morte porque nunca esteve só na memória.

## Estado de UI

**Estado de UI é onde o usuário estava, e o que ele tinha começado.** Ele só importa se o usuário
voltar a esta tela, e precisa parecer, quando ele voltar, que nada aconteceu. O guia do Android sobre
salvar estado de UI resume a expectativa numa linha: o usuário espera que o estado de UI do app
continue o mesmo se ele trocar de app por um tempo e depois voltar, e, quando o sistema destruiu o
app no meio disso, salvar e restaurar é o que torna essa destruição transparente para ele. Três
pedaços são típicos:

- o que estava selecionado: o curso aberto, a aba, o item de uma lista. Salvo como id.
- onde o usuário estava: uma posição de rolagem, uma seção expandida. Salvo como número ou flag.
- o que ele tinha digitado e não enviado: o formulário pela metade. Salvo como as strings cruas,
  mesmo quando ainda não são válidas, porque "4" a caminho de "45" é exatamente o que o usuário
  espera encontrar.

**O rascunho é o pedaço que o usuário percebe.** Perder uma posição de rolagem irrita; perder três
frases que alguém digitou é o relato de bug que diz "o app apagou meu trabalho".

## Efêmero

**Algum estado é mais barato de reconstruir que de salvar.** O destaque de um botão pressionado, o
indicador de carregamento de uma lista, um valor calculado a partir dos dados, como o total da semana.
Salvar a resposta de `weekTotal` seria salvar uma cópia de algo que os dados já dizem, e a cópia pode
ficar velha. Calcule de novo.

## A pergunta que os separa

Para cada pedaço de estado, pergunte o que o usuário espera depois de dois eventos: o sistema mata o
app enquanto ele está em segundo plano, e o usuário arrasta o app para fora de propósito.

| | depois de uma morte pelo sistema | depois de o usuário fechar |
|---|---|---|
| dados | continuam lá | continuam lá |
| estado de UI | restaurado | sumiu, e está certo: ele escolheu começar de novo |
| efêmero | reconstruído | reconstruído |

**A linha do meio é o assunto desta aula.** Estado de UI sobrevive ao sistema e não ao usuário, e as
ferramentas das plataformas são construídas exatamente em volta dessa linha, como a etapa depois da
próxima mostra.
