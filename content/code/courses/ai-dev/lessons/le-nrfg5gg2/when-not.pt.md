---
title: Quando não usar um
version: 1
---

Um assistente é rápido em produzir código e não tem como ser responsável por ele. Na maior parte
do tempo tudo bem, porque você é responsável e confere. **Os casos em que não usar um são aqueles
em que você não consegue conferir o que ele lhe dá**, ou em que mandar o código não é decisão sua.

## Quando você não consegue julgar a resposta

- **Um domínio que você não conhece.** Se você não teria conseguido escrever o código, também não
  consegue revisá-lo, e uma resposta errada e fluente parece igual a uma certa. Use o assistente
  para explicar e apontar documentação, e escreva o código quando entender.
- **Código sensível para segurança.** Autenticação, permissões, criptografia, qualquer coisa que
  interprete entrada não confiável. Os erros aqui não reprovam um teste; funcionam, e são
  explorados depois. Um `verify_signature` gerado que devolve `True` numa entrada malformada passa
  em todo teste que só confere assinaturas válidas. A aula 11 volta a isso.
- **Dinheiro, datas e unidades**, onde o código óbvio está sutilmente errado. A aula 3 seção 07
  achou um bug de arredondamento em quatro linhas do próprio código da loja. São os lugares para
  escrever os testes primeiro e só ficar com a sugestão do assistente se ela passar neles.

## Quando a decisão não é sua

- **O código do seu empregador e a política dele.** Se o código pode ser mandado a um terceiro,
  que ferramentas são aprovadas, se há um contrato que mantém o código fora do treino: isso tem
  resposta na sua organização, e a resposta vem antes de a extensão ser instalada.
- **Licenças.** Uma sugestão pode reproduzir de perto código dos dados de treino do modelo,
  inclusive código sob uma licença que o seu projeto não pode aceitar. Alguns assistentes oferecem
  um filtro que bloqueia sugestões parecidas com código público. Se a licença do seu projeto
  importa, descubra se o seu tem um e se está ligado.

## Quando custa mais do que economiza

- **Quando você está aprendendo.** Digitar o laço você mesmo é como o laço passa a ser seu. Um
  assistente que completa todo exercício ensina você a aceitar completações. Use-o para explicar um
  erro, não para fazê-lo sumir.
- **Quando a mudança é uma que você digitaria mais rápido do que conferiria.** Um nome trocado em
  três linhas, um erro de digitação, um valor mudado num lugar só.
- **Quando os testes ainda não existem.** A aula 3 seção 06 mostrou como fica a mudança de um
  assistente quando nada a confere: verde, e errada. A primeira coisa a pedir a um assistente num
  código sem testes é ajuda para escrever os testes, que é onde a aula 4 começa.
