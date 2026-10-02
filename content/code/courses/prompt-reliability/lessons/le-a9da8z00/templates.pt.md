---
title: Um prompt com lacunas
version: 1
---

Todo prompt deste curso foi um template sem que ninguém o chamasse assim. O `{{message}}` no fim do
`v2-json.txt` é uma lacuna, e o `pl run` a preenche quarenta vezes, uma para cada linha do conjunto
de teste. **O prompt que você escreve nunca é o prompt que o modelo lê**: o modelo lê aquilo em que
o template se transforma depois que as lacunas são preenchidas.

O prompt de resposta tem três lacunas, porque a Folio quer as mesmas instruções para mais de uma
loja e mais de um idioma:

```
ana@lab:~/triage$ cat prompts/reply.txt
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

`{{shop}}` e `{{language}}` são configurações, iguais para uma execução inteira. `{{message|xml}}`
vem do caso de teste, e o `|xml` depois do nome é um filtro, assunto da terceira seção desta aula.
O `pl render` preenche um template e imprime o resultado sem chamar modelo nenhum, o que faz dele o
jeito mais barato de ver o que o modelo vai receber de fato. O prompt de resposta serve só para
renderizar neste laboratório, porque o substituto classifica mensagens e não escreve respostas.

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"
pl: no value for {{language}}
exit status 2
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English
You write replies for Folio, an online bookshop. Write in English.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
I was charged twice for order 4471. Please refund the second payment.
</message>
```

O primeiro comando deixou o idioma de fora. O `pl render` não imprimiu prompt nenhum, nomeou a lacuna
que não conseguiu preencher e saiu com status 2, que um script consegue testar. **Um template com uma
lacuna que ninguém preencheu é recusado, não enviado.** O segundo comando preencheu as três, e o
resultado é um prompt que uma pessoa consegue ler e conferir linha por linha.

## Por que um template, e não uma cópia

A alternativa é um arquivo por loja e por idioma, e é assim que os prompts costumam começar: copiar o
inglês, trocar uma palavra, salvar com outro nome. Duas cópias de um conjunto de instruções são dois
lugares para corrigir o próximo problema, e a segunda correção é a que fica esquecida. **Com um
template, uma instrução mora num arquivo só**, e o que muda entre os usos é uma lista curta de
valores que dá para ver. Quando a equipe de atendimento decidir que o limite da resposta é 60
palavras e não 80, há uma linha para mudar.
