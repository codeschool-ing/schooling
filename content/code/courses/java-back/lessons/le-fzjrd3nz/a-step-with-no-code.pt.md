---
title: Uma frase sem código, e quanto as frases custam
version: 1
---

Uma conversa produz frases mais depressa do que alguém escreve métodos, então o Cucumber precisa
dizer alguma coisa sobre uma frase que nenhum método reivindica. Acrescente uma linha ao fim do
primeiro cenário, uma promessa que a loja nunca fez:

```
  Scenario: An order takes copies out of stock
    Given the shop has 5 copies of "The War of the Worlds"
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies left
    And she receives an e-mail confirming the order
```

e rode as *features* de novo, desta vez ficando com a contagem e com as linhas que seguem a exceção:

```
ana@vm:~/bookshop$ mvn verify -Dit.test=CucumberIT | grep -E -A 8 'Tests run:.*Cucumber|UndefinedStepException'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
io.cucumber.junit.platform.engine.UndefinedStepException: 
The step 'she receives an e-mail confirming the order' is undefined.
You can implement this step using the snippet(s) below:

@Then("she receives an e-mail confirming the order")
public void she_receives_an_e_mail_confirming_the_order() {
    // Write code here that turns the phrase above into concrete actions
    throw new io.cucumber.java.PendingException();
}
```

Um **passo indefinido** (*undefined step*) é um erro, e não um passo pulado: `Errors: 1`, com o nome do
cenário, e um build que falhou. Os passos antes dele rodaram, então o pedido foi feito de verdade;
depois o cenário parou na linha que nenhum método reivindica, e o relatório *pretty* pôs um
quadradinho onde estaria o tique. O Cucumber 8 não tem
configuração que deixe um passo indefinido passar, e esse é o padrão certo: uma frase que não roda
nada seria lida como uma verificação que se sustenta.

O que ele imprime no lugar é um **snippet**, o esqueleto do método que falta. A frase virou o
padrão, a palavra-chave é `@Then` porque um `And` continua o `Then` de cima, e o nome do método é a
frase em *snake case* (`cucumber.snippet-type=camelcase` pede a outra convenção). O corpo lança
`PendingException`, a palavra do Cucumber para *escrito mas não feito*, então colar o snippet e
esquecer dele não deixa o cenário verde por acidente.

O snippet também é onde a conversa volta. A loja não manda e-mail, então essa frase ou é um desejo
que ninguém combinou, e sai, ou é trabalho novo, e precisa dos três de novo antes de precisar de um
método. Tire a linha antes de seguir.

## Um passo que falha

Uma falha se lê do mesmo jeito, no nível da frase. Troque `6400` por `6300` no `Then` do primeiro
cenário e rode:

```
ana@vm:~/bookshop$ mvn verify -Dit.test=CucumberIT | grep -E ' # (classpath|com\.example)|expected:|but was:|Tests run:.*Cucumber'
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
Scenario: An order takes copies out of stock               # classpath:features/ordering.feature:8
  ✔ Given the customer "ana" has signed in                 # com.example.bookshop.acceptance.OrderingSteps.theCustomerHasSignedIn(java.lang.String)
  ✔ Given the shop has 5 copies of "The War of the Worlds" # com.example.bookshop.acceptance.OrderingSteps.theShopHas(int,java.lang.String)
  ✔ When she orders 2 copies of "The War of the Worlds"    # com.example.bookshop.acceptance.OrderingSteps.sheOrders(int,java.lang.String)
  ✘ Then the order is accepted with a total of 6300 cents  # com.example.bookshop.acceptance.OrderingSteps.theOrderIsAccepted(int)
        expected: 6300
         but was: 6400
  ↷ And "The War of the Worlds" has 3 copies left          # com.example.bookshop.acceptance.OrderingSteps.hasCopiesLeft(java.lang.String,int)
Scenario Outline: An order for more copies than the shop has is refused # classpath:features/ordering.feature:22
  ✔ Given the customer "ana" has signed in                              # com.example.bookshop.acceptance.OrderingSteps.theCustomerHasSignedIn(java.lang.String)
  ✔ Given the shop has 5 copies of "Persuasion"                         # com.example.bookshop.acceptance.OrderingSteps.theShopHas(int,java.lang.String)
  ✔ When she orders 6 copies of "Persuasion"                            # com.example.bookshop.acceptance.OrderingSteps.sheOrders(int,java.lang.String)
  ✔ Then the order is refused as out of stock                           # com.example.bookshop.acceptance.OrderingSteps.theOrderIsRefused()
  ✔ And "Persuasion" has 5 copies left                                  # com.example.bookshop.acceptance.OrderingSteps.hasCopiesLeft(java.lang.String,int)
Scenario Outline: An order for more copies than the shop has is refused # classpath:features/ordering.feature:23
  ✔ Given the customer "ana" has signed in                              # com.example.bookshop.acceptance.OrderingSteps.theCustomerHasSignedIn(java.lang.String)
  ✔ Given the shop has 0 copies of "Persuasion"                         # com.example.bookshop.acceptance.OrderingSteps.theShopHas(int,java.lang.String)
  ✔ When she orders 2 copies of "Persuasion"                            # com.example.bookshop.acceptance.OrderingSteps.sheOrders(int,java.lang.String)
  ✔ Then the order is refused as out of stock                           # com.example.bookshop.acceptance.OrderingSteps.theOrderIsRefused()
  ✔ And "Persuasion" has 0 copies left                                  # com.example.bookshop.acceptance.OrderingSteps.hasCopiesLeft(java.lang.String,int)
expected: 6300
 but was: 6400
expected: 6300
 but was: 6400
```

O X marca a frase que falhou, e embaixo dela o AssertJ diz o que esperava e o que voltou. Desta
vez a contagem diz `Failures: 1`, e não `Errors: 1`: uma verificação que rodou e não se sustentou,
não uma frase que nada conseguia rodar. As últimas quatro linhas são o resumo do Failsafe dizendo a
mesma coisa mais duas vezes. O passo
seguinte é marcado com uma seta curva, **pulado** (*skipped*): quando um passo falha, o Cucumber não
roda mais nada naquele cenário, porque todos os passos seguintes supunham que os anteriores
valiam. Os outros dois cenários não são afetados, que é o que manter um `When` por cenário compra.
A pergunta que a falha faz continua sendo da conversa: ou o exemplo estava errado, ou o código está.
Ponha o `6400` de volta.

## Quanto as frases custam

Conte o que três cenários custaram a este projeto: um BOM e quatro dependências, um arquivo de
*feature*, uma classe de suíte, uma classe de configuração e 86 linhas de passos, com uma camada de
correspondência entre cada frase e o seu método. O `BooksApiIT` da aula 20 verifica uma cliente
fazendo um pedido num método de umas vinte linhas. Os dois fazem as mesmas chamadas HTTP contra o
mesmo banco.

O preço é pago em três lugares. O primeiro é a **indireção**: para achar o que um passo faz, você vai
da frase ao método pelo texto dela, o que um editor com um plugin do Cucumber transforma num clique
e qualquer outra coisa numa busca. O segundo é um vocabulário para cuidar. As frases são globais em
toda a *glue*, então a próxima *feature* que quiser *the shop has 5 copies of …* a reaproveita, e
uma que quiser quase as mesmas palavras ou se dobra para caber ou acrescenta uma quase duplicata.
Alguém precisa manter os passos uma língua, e não uma pilha. O terceiro é que toda frase renomeada
se solta do seu código. O Cucumber avisa em voz alta, como o snippet acima mostrou, mas alguém ainda
precisa consertar.

Compensa quando pessoas que não leem Java leem os cenários ou escrevem cenários novos: um dono de
produto que os aprova num pull request, testadores que compõem exemplos novos a partir de passos que
já existem, um auditor que pergunta qual regra um teste prova. Aí o arquivo de *feature* é o
registro compartilhado mais barato que a equipe tem, e ele quebra o build quando deixa de ser
verdade.

Não compensa quando só desenvolvedores leem os cenários. As frases viram uma segunda cópia do que um
teste JUnit com um bom `@DisplayName` (aula 18) já diz, e a *glue* vira código sem leitor. Uma
equipe que instala o Cucumber "para os testes" e nunca faz a conversa fica com o custo sem o
benefício, que é a imagem errada do começo desta aula, agora com a conta junto. **A ferramenta é
opcional; os exemplos combinados antes do código não são**, e eles cabem num nome de teste tão bem
quanto num arquivo de *feature*.
