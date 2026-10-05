---
title: Estreitar o que entra
version: 1
---

Uma imagem comum do tratamento de entrada para um modelo é que não há nada a tratar: o modelo lê
texto, então o que o usuário digitou segue adiante, e a verificação acontece na resposta. **Todo campo
que chega a um prompt é algo sobre o que o modelo vai tentar agir**, e quanto menos houver, e quanto
mais tiver formato conhecido, menos há para dar errado. A aula 2 mostra o que texto livre num prompt
pode fazer nas mãos de alguém que tenta; esta aula trata da metade mais barata, que é decidir o que
pode entrar.

A entrada de trabalhos da Tarefa recebe o pedido de um cliente e pede a um modelo que o classifique e
sugira um preço. O pedido não é uma caixa de texto. Ele tem quatro campos, e cada um tem uma regra:

```
ana@lab:~/guard$ cat data/input-rules.json
{
 "fields": {
  "title": {
   "type": "string",
   "required": true,
   "maxLength": 80
  },
  "description": {
   "type": "string",
   "required": true,
   "maxLength": 2000
  },
  "category": {
   "type": "string",
   "required": true,
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "budget_cents": {
   "type": "integer",
   "required": true,
   "minimum": 5000,
   "maximum": 5000000
  }
 }
}
ana@lab:~/guard$ head -1 data/inputs.jsonl
{"id": "in-1", "title": "Logo for a bakery", "description": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "category": "design", "budget_cents": 120000}
```

Seis requisições, escritas pelo curso, cada uma quebrando uma regra diferente, menos a primeira:

```
ana@lab:~/guard$ guard check-in data/inputs.jsonl; echo "exit $?"
in-1   ok
in-2   REJECT  description: 5145 characters, limit 2000
in-3   REJECT  field 'priority' is not accepted
in-4   REJECT  category: 'photography' is not one of design, development, writing, translation, marketing
in-5   REJECT  description: U+200B zero width space x3
               description: U+202C pop directional formatting x1
               description: U+202E right-to-left override x1
in-6   REJECT  budget_cents: expected integer, got str
exit 1
```

## O que cada regra compra

**Uma lista de campos aceitos.** O `in-3` traz um campo `priority` que o formulário nunca ofereceu. Um
montador de requisição que copia para o prompt todo campo que recebe transforma qualquer campo extra
numa instrução que o desenvolvedor nunca escreveu; aceitar só os campos nomeados fecha esse caminho
sem custo. É o mesmo movimento da lista de finalidade da aula 22, aplicado na outra direção.

**Listas fechadas onde a resposta é fechada.** `category` aceita um de cinco valores. *Photography*
pode ser uma ótima categoria para a Tarefa acrescentar um dia. Até lá é um valor que o resto do
sistema não sabe tratar, então é recusado na porta, com uma mensagem que diz quais valores existem.

**Tipos, e dinheiro como centavos inteiros.** O `in-6` manda o orçamento como o texto `"1.200,00"`, que
é como um brasileiro escreve e que um parser pode ler como um vírgula dois, como mil e duzentos, ou não
ler. A regra exige um número inteiro de centavos, que só tem uma leitura.

**Um tamanho.** O `in-2` tem 5.145 caracteres, a maioria um histórico da empresa colado de um documento.
Dois mil caracteres é a escolha do curso para uma descrição de trabalho. O limite protege a conta, já
que cada caractere é pago como token de entrada em cada chamada, e também limita quanto material pode
distrair o modelo.

**Nenhum caractere invisível.** O `in-5` parece, na maioria das telas, uma frase comum sobre uma
padaria em Recife. Ele contém três espaços de largura zero e um override da direita para a esquerda,
que inverte como o texto depois dele é desenhado. O modelo lê os caracteres na ordem em que estão
gravados, e uma pessoa revisando a requisição os vê na ordem em que são desenhados. **Texto que se lê
diferente para a pessoa e para o modelo** não tem lugar legítimo numa descrição de trabalho, então a
regra lista esses caracteres pelo código e os recusa.

## Recusar ou limpar

Toda regra aqui recusa a requisição e diz por quê, e a alternativa, consertar em silêncio, tenta:
cortar a descrição em 2.000 caracteres, descartar o campo desconhecido, tirar os caracteres
invisíveis. Limpar é certo quando o conserto é certo e inofensivo, como aparar espaços nas pontas de
um título. É errado quando muda o que a pessoa quis dizer sem avisá-la. Uma descrição cortada em 2.000
caracteres pode perder a única frase que importava, e um cliente que conhece o limite pode escolher o
que cortar.
