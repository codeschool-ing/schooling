---
title: Critérios de aceitação em Dado, Quando, Então
version: 1
---

**Critérios de aceitação são as condições que uma funcionalidade precisa cumprir para o cliente
aceitá-la**, combinadas antes de ela ser construída. Eles costumam ser confundidos com o requisito a
que pertencem, e a diferença é o ponto. O R5 diz "estudante paga meia". Um critério de aceitação diz
como qualquer pessoa, a gerente inclusive, vai conferir isso no dia: que pedido, que botão, que
número na tela.

Times ágeis escrevem critérios em toda história, e o formato que a maioria usa vem do
desenvolvimento guiado por comportamento (BDD): **Dado** uma situação de partida, **Quando** alguém
faz uma coisa, **Então** acontece algo que se pode ver. Ele se lê como uma frase, e por isso um
cliente consegue escrevê-lo, e tem as três partes de um caso de teste da aula 2, e por isso um
testador consegue rodá-lo.

## Critérios para o boxoffice

Aqui vão quatro, para a parte do boxoffice que mais importa ao teatro. As palavras `Funcionalidade`,
`Cenário`, `Dado`, `Quando`, `Então` e `E` são as palavras-chave do formato; todo o resto é a
linguagem da gerente.

```localised
Funcionalidade: o preço de um pedido

  Cenário: estudante paga meia
    Dado que um membro confirmado está reservando 2 ingressos para Hamlet, a R$ 80,00 cada
    E marca "Student (half price)"
    Quando confirma a reserva
    Então o pedido mostra 50% de desconto
    E o total é R$ 80,00

  Cenário: descontos não se somam
    Dado que um membro confirmado está reservando 5 ingressos para Hamlet
    Quando confirma a reserva
    Então o pedido mostra 15% de desconto
    E o total é R$ 340,00

  Cenário: seis ingressos é o máximo num pedido
    Dado que um membro está reservando 7 ingressos para Hamlet
    Quando confirma a reserva
    Então nenhum pedido é criado
    E a página diz "You can book 1 to 6 tickets."

Funcionalidade: a reserva fecha antes do espetáculo

  Cenário: uma hora antes de abrir a cortina, a reserva fecha
    Dado que são 19:01 do dia de The Seagull, que começa às 20:00
    Quando um membro tenta reservar 2 ingressos para ela
    Então nenhum pedido é criado
    E a página diz "Booking for this show has closed."
```

As mensagens entre aspas ficam em inglês porque é assim que o boxoffice as escreve na tela. Três
coisas tornam esses critérios úteis em vez de decorativos.

**Cada Então pode ser visto.** "O total é R$ 80,00" está na página do pedido ou não está. Compare com
um critério que um cliente escreve na primeira tentativa, "estudantes pagam um preço justo":
ninguém consegue reprová-lo, então ninguém consegue aprová-lo também, e a discussão que ele adia
chega no dia do aceite.

**Cada cenário confere uma coisa só.** O primeiro cenário é sobre a regra do estudante, então todo o
resto fica parado: o mesmo espetáculo e a mesma quantidade, um membro. Se ele falhar, ninguém
precisa adivinhar qual de três mudanças causou a falha.

**Os números são calculados antes.** R$ 340,00 são cinco ingressos a R$ 80,00 com 15% de desconto, o
maior entre os 10% do membro e os 15% do grupo. Um critério que diz "o desconto certo" deixa a conta
para quem roda, e a coloca onde os erros se escondem. A aula 5 montou a tabela de decisão completa
do R5; um critério escolhe as linhas que importam ao cliente e as escreve nas palavras dele.

## De onde vêm, e para onde vão

**O cliente escreve os critérios, com ajuda.** A parte do testador é perguntar até que todo Então
possa ser visto: "o que o cliente vê se pedir sete?", "a hora conta a partir do horário impresso
no ingresso?". Este é o teste mais barato que existe, porque acha erros no requisito antes de
alguém escrever código. Um time que escreve critérios junto costuma chamar isso de **three
amigos**: uma pessoa do negócio, uma do código e uma do teste, em volta de uma história.

**Eles viram os casos do UAT.** Cada cenário já é um caso: Dado é a pré-condição, Quando é o passo,
Então é o resultado esperado. A Ana copia os cenários para o roteiro da sessão com as mesmas
palavras, para que a gerente teste as próprias frases, e não uma tradução delas.

**Uma máquina também pode rodá-los.** Ferramentas como Cucumber e behave leem arquivos escritos
nesse formato e os rodam contra a aplicação, com código por trás de cada linha; as duas aceitam as
palavras-chave em português. Isso é automação e pertence ao `web-automation`; aqui basta reconhecer
um arquivo `.feature` quando o vir, e saber que o formato foi pensado primeiro para pessoas.

## O que um critério não é

Não é o teste inteiro. Esses quatro não dizem nada sobre a caixa de saída, o layout no celular ou o
reembolso de um pedido já usado, e os testes de transição de estado da aula 5 e as telas da aula 7
continuam importando. Critérios de aceitação são o mínimo do cliente, escrito nas palavras do
cliente: **passar neles quer dizer que o cliente concordou que o produto dá conta do trabalho, e não
diz nada sobre o que ninguém pensou em escrever.** A próxima seção trata de como uma sessão com o
cliente acha uma parte disso.
