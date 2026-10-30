---
title: O tipo desperdiçado, e como saber se você o tem
version: 1
---

**A recomposição não é um custo a minimizar; a recomposição desperdiçada é.** O Compose foi feito
para rodar composables de novo, e um composable que roda de novo a cada mudança que lê está fazendo o
trabalho dele. As quatro seções antes desta mostraram, cada uma, um jeito de o trabalho crescer além
do que a tela precisa: um pai que lê um valor só para repassá-lo (seção 02), um argumento
reconstruído a cada execução (seção 03), um tipo em que o compilador não pode confiar (seção 04), uma
fonte que muda muito mais que o resultado (seção 05). E a seção 06 mostrou o que nem é sobre
velocidade, um valor lembrado que cai no item errado.

**Meça antes de mudar qualquer coisa.** Cada correção acima custa um pouco de legibilidade: uma lambda
em vez de um valor, um `remember` em volta de um argumento, uma linha num arquivo de estabilidade que
precisa continuar verdadeira. Elas valem onde um composable roda a cada quadro, durante uma rolagem,
uma animação ou um arrasto, e quase nunca onde roda uma vez por toque. A contagem com `SideEffect`
usada nesta aula funciona em qualquer teste. O Layout Inspector do Android Studio mostra contagens de
recomposição e de pulos para cada composable de um app rodando, segundo a documentação do Google;
**não executado** aqui, já que precisa do Studio e de um aparelho.

**Meça um build de release.** Um build de debug roda o runtime do Compose sem as otimizações que o R8
aplica, e a documentação do Google sobre desempenho no Compose diz para julgar o desempenho num build
de release, com as configurações da aula 22. Uma tela que engasga no debug pode ser fluida no
release, e o contrário é raro.

## Uma lista curta para guardar

- Leia o estado tão baixo na árvore quanto o valor é usado; passe uma lambda quando um valor muda a
  cada quadro.
- Não construa objetos no corpo para repassá-los; use `remember` neles, ou passe aquilo de que são
  feitos.
- Leia o relatório do compilador antes de decidir que um tipo é o problema, e acrescente uma classe ao
  arquivo de estabilidade só quando a documentação dela promete que ela nunca muda.
- Use `derivedStateOf` quando um resultado muda muito menos que a fonte, e só então.
- Dê a cada item desenhado num laço uma chave estável e única.
