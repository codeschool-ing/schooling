---
title: O que testar, e onde
version: 1
---

**Teste o que machucaria um estudante se quebrasse em silêncio, na camada mais barata que consegue
enxergar.** Essa frase decide a maioria dos casos, e os testes do próprio planner mostram como.

| o que pode quebrar | quem perceberia, e quando | onde este curso testa |
|---|---|---|
| o total da semana conta os dias errados | ninguém, até um domingo | JUnit puro, seção 03 |
| um toque não move o total | o estudante, na hora | teste de Compose no Robolectric, seção 04 |
| um padding ou uma cor muda por acidente | quem revisa, se olhar | teste de captura, seção 05 |
| a sincronização é agendada vinte vezes | ninguém; a bateria acaba | Robolectric com o test driver do WorkManager, aula 18 |
| um lembrete é postado sem permissão | ninguém; é descartado em silêncio | Robolectric, aula 19 |
| uma permissão recusada deixa um botão morto | o estudante, frustrado | um registro falso no Robolectric, aula 20 |
| a notificação nunca chega à gaveta num celular de verdade | o estudante, bem depois | instrumentado, seção 06, não executado |

**As falhas silenciosas importam mais**, e são a maior parte da tabela. Uma queda é relatada; um total
errado aos domingos, ou uma notificação descartada sem erro, pode ser lançado e continuar lançado.
Cada linha da tabela saiu da pergunta "o que ninguém perceberia?" e do teste escrito para isso.

## O que não testar

**Não o framework.** Um teste de que o Compose desenha um `Text` com a string que recebeu testa o
código do Google, que o Google já testa. Teste as suas decisões: qual string, em qual condição.

**Não a implementação.** Um teste que lê uma variável privada, ou conta quantas vezes uma função foi
chamada dentro da tela, quebra sempre que o código é arrumado, e passa quando a tela está errada de
um jeito que ele não contava. O teste da seção 04 confere o que o estudante vê.

**Não tudo por capturas.** Uma captura por tela e estado é uma rede de segurança para a aparência;
uma captura não diz *qual* número está errado, e cinquenta delas falham juntas a cada atualização de
biblioteca. Asserções dizem o que se quer; imagens pegam o que ninguém pensou em afirmar.

## Quando rodar

A suíte inteira desta aula rodou de novo em 21 segundos na seção 02, então pode rodar a cada mudança,
na sua máquina e na integração contínua, que é o assunto do curso `testing-cicd`. Os instrumentados,
quando você tiver um aparelho, ficam num pipeline mais lento que roda menos vezes, antes de uma versão
e não a cada commit. **Um teste que só roda antes das versões é um teste cujas falhas chegam
tarde**, e esse é o argumento para manter o máximo possível à esquerda da figura da seção 02.
