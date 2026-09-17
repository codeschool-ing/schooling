---
title: Onde todo mundo começa, e onde isso para
version: 1
---

Quase todo banco de dados do mundo começou como uma planilha, e a maioria funcionou. Vale dizer
isso antes de qualquer outra coisa, porque o modelo relacional costuma ser ensinado como se a
planilha fosse um erro. Não é um erro. É a ferramenta certa até um dia específico, e aprender a
reconhecer esse dia é a maior parte do que esta aula serve.

Aqui está um caso real. Uma loja pequena guarda seus pedidos numa única planilha:

| pedido | data | cliente | email | cidade | item | qtd | preço unit. |
|---|---|---|---|---|---|---|---|
| 1001 | 2026-03-02 | Ana Lopes | ana@example.com | Porto | Chaleira | 1 | 34,90 |
| 1002 | 2026-03-02 | Bruno Sá | bruno@example.com | Lisboa | Chaleira | 2 | 34,90 |
| 1003 | 2026-03-04 | Ana Lopes | ana@example.com | Porto | Torradeira | 1 | 51,00 |
| 1004 | 2026-03-07 | Ana Lopes | ana@exmaple.com | Porto | Chaleira | 1 | 34,90 |

Quatro linhas. Tudo o que uma pessoa precisa está na linha à frente dela, que é exatamente por que
esse formato é tão atraente — você lê uma linha e sabe a história inteira.

Olhe a linha 1004.

## O mesmo fato, escrito mais de uma vez

`ana@exmaple.com`. O `a` e o `m` estão trocados, e isso aconteceu porque um humano digitou o
endereço pela terceira vez. Ninguém digitou errado de propósito; digitou errado porque foi pedido
que digitasse de novo.

**A planilha tem três cópias do email da Ana e nenhuma opinião sobre qual está certa.** Não pode
ter. Cada linha é uma afirmação separada, e nunca foi dito à planilha que as três linhas são sobre
a mesma pessoa. Para ela, `ana@example.com` e `ana@exmaple.com` são dois textos que por acaso se
parecem.

Esta é a falha em torno da qual todo o resto do curso está organizado, então vale nomeá-la com
precisão. Não é "há um erro de digitação". Erros de digitação são inevitáveis. É que **a planilha
não consegue te dizer que há um**, porque ela não guarda registro do que um cliente *é* — só do
que cada linha diz.

Agora considere as consequências comuns:

- A Ana muda para Braga. Você precisa achar todas as linhas dela e mudar a cidade em cada uma.
  Esqueça uma e ela passa a morar em dois lugares.
- O email da Ana é corrigido na linha 1004 mas não na 1003. Qual está certo? Nada no arquivo
  responde isso.
- Você quer enviar um email a cada cliente, uma vez. Não existe lista de clientes. Existe uma lista
  de *pedidos*, e você tem que adivinhar que duas linhas são a mesma pessoa comparando texto.

Cada um desses é a mesma falha com outra roupa: **um fato está guardado em vários lugares, então os
lugares podem discordar.**

## E a pergunta que ela não consegue responder

A falha acima é sobre escrita. Existe uma segunda, sobre leitura, e é a que normalmente decide a
questão.

> Quais clientes pediram pelo menos duas vezes em março e não pediram mais desde então?

Leia a planilha de novo e tente enxergar o formato dessa resposta. Você precisa agrupar linhas por
cliente — mas "cliente" é um pedaço de texto, então você está agrupando por dois textos coincidirem,
e a linha 1004 vai cair fora do grupo por causa de uma letra trocada. Depois você precisa da
*ausência* de linhas posteriores, que não é algo que se enxergue olhando as linhas que estão lá.

Uma planilha responde **perguntas que alguém planejou**. Você pode acrescentar uma coluna, escrever
uma fórmula, montar uma tabela dinâmica — e cada uma dessas coisas é uma pessoa decidindo, de
antemão, que aquela pergunta importa. A resposta existe porque alguém a construiu.

**Um banco de dados responde perguntas que ninguém planejou.** Isso não é uma diferença de grau. É
o ponto inteiro, e é comprado com exatamente uma ideia.

## A ideia única

> Cada fato é escrito uma vez, em um lugar, e tudo o que precisa dele aponta para ele.

A Ana é registrada uma vez, como cliente. Os pedidos dela não contêm o nome, o email nem a cidade
dela; contêm um ponteiro para ela. Corrija o email no único lugar onde ele mora e todo pedido que
ela já fez fica correto, porque nenhum deles guardava uma cópia.

Isso é o modelo relacional. Todo o resto desta aula — chaves, chaves estrangeiras, restrições, o
`NULL` que pega todo mundo — é maquinário para fazer essa frase funcionar.

## Dois limites honestos

**Isso não é de graça.** A planilha de quatro linhas acima vira três tabelas, e ler um pedido agora
significa olhar em três lugares em vez de um. Para quatro linhas isso é simplesmente pior. A troca
só compensa quando os dados sobrevivem a quem os digitou, quando mais de uma pessoa escreve neles,
ou quando alguém vai fazer uma pergunta que você ainda não pensou. Se nada disso vale, a planilha é
a ferramenta certa e usar um banco é exibicionismo.

**E o modelo relacional não é o único.** Existem bancos de documentos, de grafos, de chave-valor e
colunares, cada um bom em algo que este não é. São outro curso. O que faz deste o lugar para
começar é que o modelo relacional é o mais antigo, o mais implantado, e aquele contra o qual as
ideias dos outros costumam ser explicadas.
