---
title: Primeiro uma planilha, e quando ela deixa de bastar
version: 1
---

A maioria dos times que têm uma ferramenta de casos começou com uma planilha, e isso não é um erro
de que se envergonhar. **Uma planilha é uma ferramenta de casos com uma tabela só: uma linha por
caso, uma coluna por execução.** Não custa nada, qualquer pessoa abre, e para uma testadora e um
produto ela faz tudo o que a seção 01 desta aula pediu de uma ferramenta. Esta seção entrega os
casos do boxoffice nessa forma, lê a planilha do jeito que uma ferramenta leria e depois lista os
sinais de que um time cresceu além dela.

## Os casos do boxoffice, como arquivo

O arquivo abaixo tem dezessete casos do boxoffice, os que este curso rodou até aqui, com os
resultados de duas execuções: uma na versão 1.0 e uma na 1.1. Ele é CSV, valores separados por
vírgula, a forma em texto puro que todo programa de planilha abre e salva. Crie um arquivo novo no
seu diretório `boxoffice`, cole o bloco nele com o botão de copiar e salve. Salve como `cases.csv`,
exatamente esse nome, porque a aula 19 o lê:

```
id,requirement,title,steps,expected,1.0,1.1
TC-01,R1,Shows are listed,Open the home page,"Three shows, each with date and time, price and seats left",passed,passed
TC-02,R2,Sign up,"Sign up as Teste Um, teste1@example.org, password abcd1234","Account created, and an e-mail in the outbox",passed,passed
TC-03,R2,E-mail already used,"Sign up as Bia, member@example.org, password abcd1234",There is already an account with that e-mail.,passed,passed
TC-04,R4,Book one ticket,"As member@example.org, book 1 ticket for Hamlet",Order 1001 reserved.,passed,passed
TC-05,R4,Book six tickets,"As member@example.org, book 6 tickets for Hamlet",Order 1001 reserved.,failed: You can book 1 to 6 tickets.,passed
TC-06,R4,Seven tickets refused,"As member@example.org, book 7 tickets for Hamlet",You can book 1 to 6 tickets.,passed,passed
TC-07,R4,Seats go down,"As member@example.org, book 1 ticket for Hamlet, open the home page",Hamlet has 79 seats left,passed,passed
TC-08,R5,Member discount,"As member@example.org, book 2 tickets for Hamlet","10% off, R$ 144,00",passed,passed
TC-09,R5,Largest discount only,"As member@example.org, book 5 tickets for Hamlet","15% off, R$ 340,00","failed: 25% off, R$ 300,00",passed
TC-10,R5,Student pays half,"As member@example.org, tick Student, book 2 tickets for Hamlet","50% off, R$ 80,00",passed,"failed: 10% off, R$ 144,00"
TC-11,R7,Quantity in words,"As member@example.org, book Hamlet typing the word two as tickets",A sentence saying what is wrong,"failed: error 500, a traceback","failed: error 500, a traceback"
TC-12,R6,Pay an order,"Book 1 ticket for Hamlet, press Pay",State: paid,passed,passed
TC-13,R6,No refund after use,"Book 1 ticket for Hamlet, press Pay, Use, Refund","Refused, and the state stays used",failed: refunded,failed: refunded
TC-14,R6,Message for a refused move,"Book 1 ticket for Hamlet, press Use",An order that is reserved cannot be used.,,failed: says cannot be useed
TC-15,R6,No refund once started,"Book and pay for The Seagull before 19:00, press Refund after 20:00","Refused, and the state stays paid",,failed: refunded
TC-16,R8,Shows on a phone,Open the home page in a window 360 pixels wide,Nothing scrolls sideways,failed: scrolls sideways,failed: scrolls sideways
TC-17,R9,Every field labelled,"Open the Book page, check the label of each field",Every field has a label,,failed: Tickets has no label
```

Abra no LibreOffice Calc, no Google Planilhas ou no Excel para vê-lo como tabela. Uma armadilha: o
Excel configurado em português espera ponto e vírgula entre as colunas, e abre este arquivo com
tudo na coluna A. Importe em vez de abrir, em **Dados**, **De Texto/CSV**, e escolha a vírgula como
delimitador.

Todo caso parte de um boxoffice novo, parado e iniciado de novo, e é por isso que dois deles podem
esperar o pedido 1001. As cinco primeiras colunas são o caso. As duas últimas são execuções, e cada
célula guarda uma de três coisas: `passed`; `failed:` seguido do que aconteceu no lugar; ou nada, o
que quer dizer que o caso não rodou naquela versão. A planilha está em inglês como o resto do
boxoffice, e os títulos dos casos são os que a aula 19 vai mostrar.

## Lendo do jeito que uma ferramenta leria

**Descendo uma coluna de execução, ela é uma execução.** A coluna da 1.1 tem dez aprovações e sete
falhas, e cada falha diz o que se viu. A aula 19 transforma essa coluna num relatório.

**Atravessando uma linha, ela é o histórico de um caso.** O TC-05 falhou na 1.0 e passou na 1.1: é
a correção que a aula 9 fez no limite de seis ingressos. O TC-10 passou na 1.0 e falhou na 1.1: é a
regressão que a aula 10 achou, o desconto de estudante que a 1.1 quebrou. Nenhum dos dois fatos
aparece numa execução só.

**As células vazias também são histórico.** TC-14, TC-15 e TC-17 não têm resultado na 1.0 porque
ainda não existiam: foram escritos depois que as aulas 11 e 14 acharam os defeitos que eles
conferem, na 1.1. Um caso escrito a partir de um defeito é o jeito comum de uma suíte crescer, e a
célula vazia registra com honestidade que ninguém perguntou isso à 1.0.

**Um filtro na coluna de requisito é rastreabilidade.** Filtre por R5 e você tem os três casos de
desconto e seus resultados; filtre por R3 e não vem nada, o que diz que o link de confirmação não
tem nenhum caso neste arquivo. Uma lacuna que se vê é a coisa mais útil que uma visão de cobertura
mostra.

## Os sinais de que um time cresceu além dela

Nenhum destes é motivo para comprar uma ferramenta no primeiro dia. Cada um é motivo quando começa a
custar tempo toda semana.

**As colunas se multiplicam.** Duas versões são duas colunas. Quatro navegadores em cada, como a
aula 7 pede, são oito, e a terceira versão faz doze. Uma ferramenta guarda as execuções como objetos
e desenha as colunas só quando você pede.

**Duas pessoas editam ao mesmo tempo.** Uma planilha num drive compartilhado ou trava ou mescla, e
um arquivo de resultados que dois testadores salvaram por cima um do outro perde um deles em
silêncio.

**A célula guarda duas coisas.** `failed: refunded` é um status e uma evidência numa string só.
Nada impede alguém de digitar `Failed` ou `fail`, e aí uma contagem de falhas erra por tantas
grafias quantas houver. Nem `refunded` é um vínculo para o relato de defeito que a aula 15
escreveria; uma ferramenta guarda o status como um item de uma lista fixa e o defeito como um
vínculo.

**O caso muda e o histórico não diz.** Se os passos do TC-13 forem reescritos no mês que vem, o
resultado da 1.0 ao lado passa a descrever passos que nunca rodaram na 1.0. Uma planilha guarda o
texto mais recente; uma ferramenta guarda a versão do caso contra a qual cada resultado foi
registrado.

**Alguém pergunta quem e quando.** Um auditor que pergunta quem marcou o TC-12 como aprovado na 1.1,
e em que dia, não tira resposta de uma célula.

**Uma regra prática: quando a planilha precisa de regras escritas sobre como editá-la, essas regras
são as funcionalidades de uma ferramenta de casos**, e o time as está mantendo à mão. Até lá, um
arquivo como este, guardado com o projeto e lido por todos, é um ótimo lugar para começar, e no dia
em que o time passar para uma das quatro ferramentas desta aula, é este arquivo que ele importa.
