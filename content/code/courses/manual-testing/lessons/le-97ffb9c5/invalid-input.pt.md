---
title: Entrada que não é número
version: 1
---

**O campo de quantidade é desenhado como uma caixa, e uma caixa aceita qualquer coisa que você
digite.** Ele tem um texto de exemplo dizendo *Tickets (1 to 6)*, e nada no navegador impede alguém
de digitar `two`, `2.5`, um espaço, ou nada, e apertar **Book**. A seção 04 desta aula particionou
os números inteiros. Esta seção pega a quarta partição, **a entrada que não é número inteiro**, e o
R7 diz o que deve acontecer com toda ela: "Entrada errada é respondida com uma frase dizendo o que
está errado, nunca com uma página de erro."

É a partição que os testadores mais esquecem, por um motivo que soa respeitável: o campo é para
números, então os casos são números. Só que o cliente tem um teclado, e um celular que sugere
palavras enquanto ele digita. Todo valor dessa partição é algo que uma pessoa de verdade pode
mandar, e o requisito já diz como o boxoffice deve responder.

## Um representante: uma palavra

A partição tem palavras, decimais, entrada vazia e símbolos, e um representante vale por ela. Aqui
é `two`, que é o que alguém digita quando lê *Tickets* e não os números depois. No navegador,
reserve Hamlet como o membro, com `two` no campo de quantidade. No terminal, a transcrição acrescenta
o código de status depois da página, que o `-w` do curl imprime:

```
ana@laptop:~/boxoffice$ curl -s -w '\n%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 237, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 179, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
500
```

**Esse é o segundo defeito da aula.** No navegador, é uma página sem título e sem links, com um
bloco de texto monoespaçado que começa com *Traceback (most recent call last)*. O status no fim da
transcrição é `500`, o código que o HTTP usa para "o servidor falhou", que é uma afirmação
diferente das recusas da seção 04: aquelas voltaram como uma página comum, com uma frase.

Lido como um cliente leria, ele quebra o R7 duas vezes. É uma página de erro, que o R7 proíbe com
todas as letras. E não é uma frase dizendo o que está errado: nada ali avisa o cliente de que a
quantidade precisa ser escrita em algarismos. Lido como um testador leria, ele diz mais. Nomeia um
arquivo no servidor, `/home/ana/boxoffice/boxoffice.py`, os números de linha dentro dele e a linha
de código que falhou. Uma página que entrega a qualquer visitante uma descrição das entranhas do
programa é um problema de segurança além de um problema para o cliente, e a aula 14 volta a ela
pelo lado de quem defende.

As aspas aparecem como `&quot;` na transcrição porque a página as escapa para o HTML, e o navegador
as mostra como aspas comuns.

## É um defeito ou três?

Se a partição está certa, todo valor dela falha do mesmo jeito, e isso merece uma conferência antes
de escrever qualquer coisa, porque muda o que o resultado diz. Entrada vazia e um decimal estão na
partição; `-1` é um número inteiro, e pertence à partição "0 ou menos" da seção 04:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=-1' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

Vazio e `2.5` respondem 500 como `two`, e `-1` recebe a frase. As partições previram exatamente
essa divisão, e isso faz do resultado um defeito só, enunciado como partição: **qualquer quantidade
que não seja número inteiro responde 500 e um traceback.** Três relatos, um por valor, descreveriam
uma falha três vezes e deixariam o desenvolvedor descobrir que são a mesma.

## Um valor inválido por caso

Um caso que testa uma partição inválida carrega um valor inválido, e todo o resto válido. É
tentador economizar casos pondo duas coisas erradas na mesma requisição, e a transcrição abaixo
mostra quanto isso custa. É o mesmo `two`, mandado com um endereço de e-mail que nenhuma conta tem:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
```

A resposta é uma frase educada sobre se cadastrar, e o traceback não acontece. **O boxoffice para
na primeira coisa errada que encontra**, e ele confere a conta antes de ler a quantidade, então o
segundo valor inválido nunca é olhado. Um testador rodando esse caso combinado teria registrado
aprovação para um campo que falha. Esse efeito se chama **mascaramento**: uma entrada inválida
esconde outra. Qual das duas um programa confere primeiro é um fato sobre o código, e um testador
de caixa-preta não pode contar com ele.

Então a regra da seção 02 desta aula agora tem um motivo. Partições válidas podem dividir um caso,
porque um valor válido deixa o programa seguir para o próximo campo. Um inválido pode pará-lo, e o
que vem depois fica sem teste.

## O que as duas técnicas acharam

Esta aula mandou 19 requisições ao boxoffice, cada uma escolhida e não chutada, e achou dois
defeitos no R4. Seis ingressos são recusados porque uma fronteira está deslocada em um; uma
quantidade que não é número derruba a requisição com um traceback. Nenhum dos dois aparecia para
quem digitasse números sensatos num campo de números. A aula 5 passa de campos isolados para regras
em que várias condições decidem um resultado juntas, e para um pedido cujo comportamento depende do
que já aconteceu com ele.
