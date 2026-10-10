---
title: Uma reprodução que um estranho consegue repetir
version: 1
---

Os passos de um relato costumam ser escritos de memória, na ordem em que as coisas aconteceram, e
carregam tudo o que aconteceu: a página que você abriu primeiro, o espetáculo que olhou e trocou, a
conta em que entrou porque era a que estava no navegador. **Uma reprodução é o caminho mais curto
de um estado conhecido até a falha**, sem nada que a falha não precise. Cada passo a mais é mais um
lugar onde o leitor faz algo ligeiramente diferente e vê outra coisa.

Chegar lá exige três movimentos: fixar o estado de onde você parte, cortar os passos até sobrar o
que importa e testar alguns vizinhos para entender o formato do defeito. O defeito da seção 02
desta aula é bom para praticar, porque é determinístico e tem um gatilho simples.

## Parta de um estado que outra pessoa consegue alcançar

O leitor não consegue alcançar *"meu notebook depois de uma hora de teste"*. Ele consegue alcançar
*"boxoffice 1.1, recém-iniciado"*, porque a aula 1 diz o que um início do zero contém: três
espetáculos com todos os lugares livres, nenhum pedido e uma conta. Então a primeira linha de toda
reprodução diz a versão, e o jeito mais barato de prová-la é perguntar à aplicação:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.1
```

**Um relato contra a versão errada desperdiça a primeira hora do leitor.** Se a 1.2 já corrigiu e
você ainda roda a 1.1, o desenvolvedor tenta, não vê nada de errado, e o relato volta marcado como
*não reproduzível*, com o defeito ainda na sua cópia e já fora da dele.

## Reduza a uma requisição

No navegador são cinco passos: abrir a página de reserva, digitar um e-mail, deixar o espetáculo,
digitar uma quantidade, clicar em Book. Eles ficam no relato, porque um leitor que queira ver a
página deve poder vê-la. Mas o navegador esconde a parte que importa, a própria requisição, e **o
curl escreve a requisição inteira numa linha**, de modo que o leitor pode colar e obter exatamente o
que você obteve:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
500
```

`-d` envia os três campos como o formulário enviaria. `-o /dev/null` descarta a página e
`-w '%{http_code}\n'` imprime só o status, então o resultado inteiro é um número que o leitor pode
comparar com o dele. Sem essas duas opções, o curl imprime a própria página:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 230, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 172, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
```

As marcas `&quot;` são o jeito de o HTML escrever aspas; no navegador a mesma página aparece com
aspas comuns. A última linha diz a falha e o valor que a causou, `'two'`, e é essa a linha que um
relato cita.

**Depois, confira se cada campo merece estar ali.** Tire um e envie de novo. Sem o e-mail, e sem o
espetáculo:

```
ana@laptop:~/boxoffice$ curl -s -d 'show=S2&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">There is no such show.</p><form method="post" action="/book">
```

Os dois respondem com uma frase de verdade, então o programa confere a conta e o espetáculo antes
de ler a quantidade, e os dois campos ficam na reprodução. A caixa de estudante nunca foi
necessária, e o navegador também não.

## Teste os vizinhos

Um valor que falha é um fato. Três valores mostram o formato, e o formato é o que o desenvolvedor
precisa para corrigir o defeito inteiro, em vez da palavra que você calhou de digitar:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book
200
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

Uma caixa vazia e um decimal falham do mesmo jeito; um número inteiro fora da faixa recebe a frase
que o R7 pede. Então o título do relato diz *uma quantidade que não é número inteiro*, e não *a
palavra two*, e um desenvolvedor que corrigisse só a palavra seria pego pelo próximo testador que
deixasse a caixa vazia. São as partições da aula 4, usadas aqui para descrever uma falha em vez de
projetar um caso.

## Quando não acontece toda vez

Este defeito falha em toda tentativa, o que facilita. Alguns não: uma falha que depende do tempo, de
duas pessoas reservando o último lugar ao mesmo tempo, ou de algo que quem relatou não percebeu.
**Aí o relato diz com que frequência**, como contagem: *"3 de 10 tentativas, mesmos passos, mesmo
build"*. "Às vezes" não diz ao leitor se a tentativa limpa dele significa que o defeito sumiu. Uma
contagem também diz quantas tentativas fazer antes de acreditar no resultado.

## No Windows

Os comandos acima rodaram num shell Unix. No PowerShell, digite `curl.exe` em vez de `curl`, porque
versões mais antigas do PowerShell respondem a `curl` com um comando próprio; as aspas simples
funcionam como estão. Isso não foi rodado para este curso. No navegador, os mesmos cinco passos dão
o mesmo traceback como único conteúdo da página, sem título, links ou rodapé.
