---
title: Um prompt com buracos
version: 2
---

Todo prompt deste curso foi um modelo de texto sem que ninguém o chamasse assim. O `{{message}}` no
fim do `v2-json.txt` é um buraco, e o `pl run` o preenche quarenta vezes, uma para cada linha do
conjunto de teste. **O prompt que você escreve nunca é o prompt que o modelo lê**: o modelo lê o que
o modelo de texto vira depois que os buracos são preenchidos.

Este prompt escreve a resposta que o cliente recebe, e tem três buracos, porque a Folio quer as
mesmas instruções para mais de uma loja e mais de um idioma. Salve-o como `prompts/reply.txt`:

```
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

`{{shop}}` e `{{language}}` são configurações, as mesmas para uma execução inteira, passadas com
`--var`. `{{message|xml}}` vem do caso de teste, e o `|xml` depois do nome é um filtro, assunto da
terceira seção desta aula. O `pl render` preenche um modelo de texto e imprime o resultado sem
chamar modelo nenhum, o que o torna o jeito mais barato de ver o que de fato vai ser mandado:

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"
pl: no value for {{language}}
exit status 1
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English
You write replies for Folio, an online bookshop. Write in English.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
I was charged twice for order 4471. Please refund the second payment.
</message>
```

O primeiro comando deixou o idioma de fora. O `pl render` não imprimiu prompt nenhum, nomeou o
buraco que não conseguiu preencher e saiu com status 1, que um script consegue testar. **Um modelo
de texto com um buraco que ninguém preencheu é recusado, não enviado.** O segundo comando preencheu
os três, e o resultado é um prompt que uma pessoa consegue ler e conferir linha por linha.

## Um modelo de texto, dois idiomas

O prompt de resposta não é um prompt de classificação, então o `pl check` não tem o que dizer sobre
ele, mas o `pl run` e o `pl show` funcionam com qualquer prompt. Três mensagens, em inglês e em
português, sem mudar nada além de um valor:

```
ana@lab:~/triage$ head -n 3 cases/dev.jsonl > cases/three.jsonl
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-en.jsonl --var shop=Folio --var language=English
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-en.jsonl
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-pt.jsonl --var shop=Folio --var language=Portuguese
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-pt.jsonl
ana@lab:~/triage$ pl show runs/reply-en.jsonl t01
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order. We will process a refund for the second payment as soon as possible. You can expect to receive an email with the refund details once the process is complete. If you have any further concerns, please don't hesitate to contact us.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 73, 9.0 s
ana@lab:~/triage$ pl show runs/reply-pt.jsonl t01
│ Olá!
│
│ Lamento saber que você foi cobrado duas vezes pelo seu pedido 4471. Estamos trabalhando para resolver o problema e devolver o valor excessivo. Você receberá uma atualização sobre o status do seu pedido assim que estivermos em contato com a nossa equipe de pagamento. Se tiver alguma dúvida, por favor não hesite em entrar em contato conosco.
│
│ Atenciosamente,
│ Equipe do Folio
stop: stop, tokens in 96, out 96, 10.7 s
```

O mesmo arquivo, a mesma mensagem, e uma resposta em cada idioma. Leia, além de contar: as duas
prometem um reembolso, *"We will process a refund for the second payment"* e *"devolver o valor
excessivo"*, e o prompt diz *Do not promise a refund or a date the shop has not agreed*. **Um modelo
de texto mantém as instruções num lugar só; não faz o modelo segui-las.** A aula 12 trata de
conferir o que uma resposta diz, e uma resposta que promete dinheiro é a primeira coisa a conferir.

## Por que um modelo de texto e não uma cópia

A alternativa é um arquivo por loja e por idioma, e é assim que os prompts costumam começar: copiar
o em inglês, trocar uma palavra, salvar com outro nome. Duas cópias de um mesmo conjunto de
instruções são dois lugares para corrigir o próximo problema, e a segunda correção é a que se
esquece. **Com um modelo de texto, uma instrução mora num arquivo só**, e o que muda entre os usos
é uma lista curta de valores que você consegue ver. Quando a equipe de atendimento decidir que o
limite da resposta é 60 palavras e não 80, ou escrever a regra do reembolso com mais firmeza, há
uma linha para mudar.
