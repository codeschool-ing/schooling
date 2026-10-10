---
title: De onde vêm os dados de teste
version: 1
---

Todo caso deste curso precisou de dados antes de poder rodar: uma conta para reservar, um
espetáculo com lugares sobrando, um pedido no estado certo. A maior parte estava lá porque o
boxoffice começa com ela, e o resto foi digitado à mão no passo anterior. **Dados de teste são tudo
o que um caso precisa que exista antes de começar, e tudo o que ele cria enquanto roda**, e de onde
eles vêm decide se o caso merece confiança, se pode ser repetido e se outra pessoa consegue rodá-lo.

## Quatro fontes

**Já embutidos.** Os dados com que a aplicação começa. O boxoffice tem três espetáculos e uma conta,
a sócia `member@example.org`, e a maioria dos casos da planilha da aula 18 se apoia neles. Dados
embutidos são os mais baratos que existem e os mais frágeis: um caso que espera 80 lugares em Hamlet
é um caso sobre o estado inicial tanto quanto sobre a reserva.

**Feitos à mão para um caso.** A conta que o TC-02 cadastra, `teste1@example.org`, existe porque
esse caso precisa de um endereço novo. Dados feitos à mão são escolhidos por um motivo, o que os
torna a fonte certa para as técnicas das aulas 4 e 5: o nome de 40 caracteres, o sétimo ingresso, o
sócio que reserva cinco. Ninguém digitaria duzentos deles.

**Gerados.** Dados que um programa inventa segundo uma regra, em qualquer quantidade, iguais toda
vez que ele roda. A seção 03 desta aula escreve um para o boxoffice, e ele cadastra cinco contas em
menos tempo do que se leva para digitar uma.

**Copiados da produção.** Dados que clientes reais criaram, com todos os casos em que ninguém
pensou. São também os dados pessoais deles, que é o assunto da seção 04 desta aula.

A maior parte do teste real mistura as quatro, e a pré-condição de um caso é onde ele diz de qual
depende.

## O que bons dados de teste têm

**São conhecidos.** Antes de um caso rodar, alguém sabe dizer exatamente o que está lá. "Algumas
contas" não é conhecido; "as cinco contas do accounts.csv" é. Quando um caso falha, a primeira
pergunta é se o produto está errado ou se os dados não eram o que o caso supunha, e só dados
conhecidos respondem a ela.

**Não são de ninguém.** Um endereço com que um teste se cadastra pode receber e-mail, então um
endereço inventado num provedor real pode chegar a um estranho real. A caixa de saída do boxoffice
guarda toda mensagem, e por isso este curso poderia ser descuidado e não é: todo endereço nele é em
`example.org`, um dos poucos domínios reservados para documentação e exemplos, onde nenhum cliente
consegue ter um endereço. A aula 22 trata do que acontece com o e-mail de teste em ambientes que de
fato enviam.

**Cobrem o assunto do caso.** Um caso sobre o desconto de estudante precisa de uma reserva de
estudante; um caso sobre espetáculo lotado precisa de um espetáculo sem lugares. Os dados do caso
saem do caso, e a técnica que escolheu os valores escolhe os dados também.

**Podem ser repostos.** Um caso que reserva seis ingressos de Hamlet deixa Hamlet com seis a menos.
Rode-o treze vezes e a décima quarta encontra dois lugares e falha, por um motivo que não tem nada a
ver com o que ele confere. A seção 05 desta aula trata de voltar a um estado conhecido, e de por que
o boxoffice torna isso incomumente fácil.

## Dados que acabam

Alguns dados são gastos pelo caso que os usa. Um pedido só pode ser pago uma vez; depois de pago, o
caso de pagá-lo não roda mais nesse pedido. Lugares acabam. Um endereço só pode ser cadastrado uma
vez, e a seção 05 desta aula esbarra nisso. **Dados consumíveis** são o motivo mais comum de um caso
passar na segunda e falhar na terça sem nada ter mudado no produto, e a correção nunca é editar o
caso até ele passar. É fazer o caso criar o que consome, ou começar cada execução de um estado em
que isso exista.
