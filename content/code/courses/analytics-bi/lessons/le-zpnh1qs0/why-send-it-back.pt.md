---
title: Para que serve, e para que não serve
version: 1
---

Um número pertence a uma ferramenta de operação quando três coisas são verdade: **alguém age sobre um
cliente de cada vez, a ação depende do número, e o número é calculado a partir de dados que a ferramenta
não tem.** Os exemplos da Lantern:

| quem | onde trabalha | o que veria | o que faria de diferente |
|---|---|---|---|
| quem liga para clientes de escritório | o CRM | o valor de cada escritório ao longo da vida e se ele ainda compra | ligar primeiro para o escritório grande que sumiu |
| o atendimento | o help desk | o segmento e o valor do cliente ao lado do chamado | responder hoje, e não na semana que vem, à reclamação de um cliente antigo |
| o marketing | a ferramenta de e-mail | uma lista de clientes com saúde *at risk* | mandar uma oferta de retorno a eles e não a todo mundo |

Cada um desses funciona sem reverse ETL — com alguém exportando uma planilha — e cada um fica melhor com
ele, porque o número no registro é o de hoje e ninguém precisa lembrar de exportá-lo.

## O que não é

- **Não é um jeito de mudar a origem.** O CRM recebe uma cópia de um campo calculado. Se o endereço do
  cliente está errado, a correção é no sistema da loja, e a próxima carga e a próxima sincronização a
  levam; escrevê-lo à mão no CRM é sobrescrito na sincronização seguinte.
- **Não é tempo real.** Uma sincronização que roda de hora em hora deixa o CRM até uma hora atrasado.
  Para uma pontuação de lead, tudo bem; para "este cliente acabou de pagar", o evento deve sair direto do
  sistema onde aconteceu.
- **Não é um painel.** Mandar quarenta campos para o CRM porque eles existem dá ao vendedor quarenta
  campos para ignorar. Mande os poucos que mudam uma ação, que é a mesma regra dos três cartões da aula
  6.
