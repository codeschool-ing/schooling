---
title: Uma rubrica com as respostas escritas
version: 2
---

As discordâncias da versão 1 não eram erros a corrigir; eram uma pergunta que a rubrica não tinha
respondido. A Ana e o Bruno as repassaram juntos e escreveram a resposta na versão 2:

```sh
cat > data/rubrics/relevance-v2.md <<'EOF'
# Relevance, version 2

Read the customer's question, the assistant's reply and the sources it was
given. Relevance asks whether the reply gives the customer what they asked
for. Whether what it says is true is faithfulness: grade that apart.

- pass: the reply gives what the question asks for, even among other
  sentences, and even if it is wrong.
  e.g. "Who pays for the return postage?" answered with "the customer pays
  for the return postage" passes here, and fails faithfulness.
- pass: the reply is the agreed refusal, "I could not find that in our
  documents.", and the shop's documents do not answer the question.
  e.g. "Can I place an order by phone?"
- fail: the reply is the agreed refusal, and the shop's documents do answer
  the question. The customer asked something the shop has written down and
  was told it had not.
  e.g. "Can I pay in instalments?" answered with the refusal.
- fail: the reply answers a different question, even one that shares the
  question's words.
EOF
```

Três coisas mudaram, e cada uma é uma técnica que vale reusar.

- **O critério diz o que ele não é.** A fidelidade é nomeada e posta de lado, para que quem nota uma
  resposta errada não a reprove em relevância. A e02 na versão nova é a âncora exatamente disso.
- **A recusa é decidida, e decidida nos dois sentidos.** Uma recusa a uma pergunta que os documentos não
  respondem dá ao cliente a verdade, e passa. Uma recusa a uma pergunta que eles respondem deixa o
  cliente sem nada, e reprova.
- **Toda regra tem um exemplo.** Uma **âncora** é uma resposta real com o seu veredicto, e resolve numa
  linha o que um parágrafo de definição deixaria em aberto. As âncoras aqui são respostas das
  execuções.

As mesmas quarenta e oito respostas, rotuladas de novo contra a versão 2:

```
ana@dev:~/obs$ python agree.py relevance-v2/ana relevance-v2/bruno
48 replies; rows relevance-v2/ana, columns relevance-v2/bruno
          pass  fail
  pass      41     3
  fail       0     4
agreement 93.8%   by chance 79.5%   kappa 0.69
apart on 3: 3 refusals, 0 other replies
  e12 2026.09.4  pass / fail  I could not find that in our documents.
  e12 2026.10.1  pass / fail  I could not find that in our documents.
  e19 2026.10.1  pass / fail  I could not find that in our documents.
```

**Kappa 0,69, e três discordâncias restantes**, todas recusas que a Ana aprovou e o Bruno reprovou: a
pergunta do Kindle nas duas versões, e o direito de arrependimento na nova. A versão 2 pede a quem
avalia que saiba se os documentos da loja respondem a uma pergunta, e a Ana, desenvolvedora, não sabia
que a página de formatos de e-book diz que eles não abrem num Kindle, nem que a política de devoluções
traz os sete dias legais. O Bruno, do atendimento, sabia. Eles conferiram juntos e reprovaram as três,
e esse veredicto é o terceiro conjunto de rótulos, `relevance-v2/agreed`. Resolver os casos que sobram
conversando, e guardar o resultado como um conjunto próprio, se chama **adjudicação**.

A lição para a próxima rodada não está nas palavras da rubrica mas no que ela pede a quem avalia: um
critério que precisa dos documentos precisa dos documentos ao lado de quem avalia, ou dos fatos do
gabarito, que é de onde vem a regra da próxima seção.

## O que uma referência precisa

Os rótulos acordados agora podem medir um juiz, porque se apoiam numa rubrica que duas pessoas leram do
mesmo jeito. Três propriedades tornaram isso possível, e são a lista de conferência de qualquer
conjunto de rótulos de referência:

1. **Cada rótulo nomeia a resposta por um id estável** e a rubrica pela versão.
2. **A concordância entre pessoas foi medida**, e é alta o bastante para os rótulos significarem algo.
3. **As discordâncias restantes foram resolvidas e guardadas** como um conjunto próprio, para que os
   rótulos individuais continuem sendo o que cada pessoa disse.

Dois avaliadores em quarenta e oito respostas é a menor versão disso que ainda mede alguma coisa. Uma
equipe que rotula com regularidade dá a uma pessoa nova algumas dezenas de respostas já acordadas, e
confere o kappa dela contra a referência antes de confiar nos seus rótulos. Também repete uma pequena
sobreposição entre avaliadores a cada rodada, porque as pessoas derivam à medida que a rubrica fica
familiar.
