---
title: Documentos jurídicos
version: 1
---

Contratos, termos, regulamentos e processos são o segundo uso clássico, e o mais exigente. Quem lê é
um advogado, um responsável por compliance ou um líder de atendimento citando os termos para um
cliente, e o que precisam não é uma resposta nas palavras do modelo. É **o texto que obriga,
localizado com exatidão, na versão que estava em vigor.**

## Perguntando quando o contrato se forma

```
ana@lab:~/rag$ python sections.py "When is the contract of sale formed?"
[1] 0.458  seller-agreement > 9. Ending the agreement
[2] 0.407  terms-of-sale > 2. Placing an order
[3] 0.402  affiliate-api > Commission
The contract is formed when we send the email confirming that your order has been dispatched. [2]
ana@lab:~/rag$ grep -n "^2\.2" data/docs/terms-of-sale.md
25:2.2 The contract is formed when we send the email confirming that your order has been dispatched.
```

A resposta certa voltou, citada palavra por palavra, e três coisas nela preocupariam um advogado.

**A seção com a melhor nota era do documento errado.** A cláusula do contrato de vendedores sobre *Ending
the agreement* marcou 0,458, acima dos termos de venda com 0,407. Os dois são contratos com cláusulas
numeradas, e os dois falam de acordos e do que acontece quando; para o modelo de embeddings são o mesmo
tipo de texto. Num corpus jurídico esse é o caso normal: todo documento é um contrato e todos soam
parecidos, então a busca tem de ser informada a que conjunto de documentos uma pergunta pertence. Os
filtros da aula 14 fazem isso.

**O número da cláusula sumiu.** A frase é a cláusula 2.2, e o `grep` diz isso. A resposta cita `[2]`,
que o `sections.py` batizou com o título, *2. Placing an order*: quem lê acha a seção, não a cláusula.
O extract-1 descarta um marcador de lista ou um número de cláusula no começo de uma linha quando separa
as frases, e pipelines reais o perdem de outros jeitos, mais comumente cortando o documento num ponto
que separa o número do texto. **Numa resposta jurídica a citação é metade da resposta**, então o número
da cláusula tem de ser guardado ao lado do pedaço e impresso na citação, que é o que a aula 5 faz com o
caminho de títulos de cada pedaço.

**Nada diz qual versão.** Estes são a versão 9 dos termos, em vigor desde 5 de janeiro de 2026, e a
cláusula 11.1 diz que os termos que valem para um pedido são os que estavam em vigor no dia em que ele
foi feito. Uma pergunta sobre um pedido de 2025 precisa dos termos de 2025, que este corpus não tem. Um
sistema de recuperação jurídica guarda todas as versões, registra as datas em que cada uma esteve em
vigor, e filtra pela data de que a pergunta trata.

## Citar, não parafrasear

Um modelo a quem se pede para responder a partir de um contrato em geral vai parafraseá-lo, porque é
assim que uma resposta parece. A paráfrase de uma cláusula é um texto novo sem força jurídica, e pode
estar sutilmente errada exatamente na palavra que importava: *dispatched* não é *delivered*, e *may* não
é *must*. O extract-1 não consegue parafrasear, e esse é o único lugar em que a limitação dele é uma
virtude. Com um modelo real, o prompt para uso jurídico pede a cláusula relevante citada literalmente
com seu número, e uma verificação depois confirma que o texto citado aparece na fonte caractere por
caractere. A aula 7 constrói essa verificação.

## O que o trabalho jurídico pede de um pipeline

- **Localização precisa**: o documento, a versão e a cláusula, em toda citação.
- **Citação literal**, conferida contra a fonte.
- **Escopo por conjunto de documentos e por data**, porque todo documento soa como todos os outros.
- **Uma recusa conservadora.** "Os documentos não dizem" é uma resposta jurídica legítima; uma cláusula
  plausível que não existe é imperícia. A regra do próprio manual de atendimento vale em dobro aqui: se
  um cliente pede o texto legal, mande o link da cláusula.
