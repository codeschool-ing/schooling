---
title: Segurança, do lado de quem defende
version: 1
---

Teste de segurança tem fama de invasão: truques espertos, ferramentas especiais, um vulto de capuz.
Parte dele é isso, feito por especialistas, sob contrato, com permissão por escrito. **A maior parte
do que um testador manual contribui é perceber**: a página que diz mais do que deveria, a regra que é
mais fraca do que parece, o endereço que deveria começar com `https` e não começa. Cada uma dessas
coisas é algo que quem defende quer saber antes de qualquer outra pessoa achar, e nenhuma precisa de
um ataque.

Uma regra vem antes, e não é formalidade. **Teste só sistemas que você recebeu permissão para testar,
e só do jeito combinado.** Testar o sistema de outra pessoa sem permissão pode ser crime em muitos
países, o Brasil entre eles, seja qual for a intenção. Tudo nesta seção acontece na sua própria
cópia do boxoffice.

## A página de erro que fala demais

A aula 4 achou que um campo de ingressos que não é um número responde com uma página de erro em vez
de uma frase. Isso quebrou o R7, um requisito funcional. Visto com os olhos de quem defende, é também
um achado de segurança, e outro relatório:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 230, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 172, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
```

No navegador, o mesmo pedido mostra o traceback como texto numa página branca. Leia-o como um
estranho leria. Ele dá o **caminho completo do programa** no servidor, `/home/ana/boxoffice/`, e com
ele, muito provavelmente, o nome da conta sob a qual o programa roda. Ele nomeia a linguagem, cita
**linhas do código-fonte** com os seus números, e mostra como a quantidade é lida e qual função a lê.
Nada disso é uma senha, e tudo isso é conhecimento de graça para quem planeja algo pior: poupa a
essa pessoa o trabalho de adivinhar. O código de status confirma que o programa falhou, em vez de
recusar:

```
ana@laptop:~$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
500
```

**O que deveria acontecer no lugar** é uma página que diz que algo deu errado, em palavras simples,
enquanto os detalhes vão para um log que só o time lê. Como defeito, isto é um relatório sobre o R7
(o da aula 4) e outro sobre exposição de informação (este), porque eles vão ser corrigidos e
conferidos por pessoas diferentes, com urgências diferentes.

Os cabeçalhos da resposta vazam um detalhe menor em toda página:

```
ana@laptop:~$ curl -s -o /dev/null -D - http://127.0.0.1:8000/
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.13.16
Date: Sat, 10 Oct 2026 07:20:02 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 931

```

A linha `Server` nomeia a versão exata do Python. É pouco, e vale uma linha num relatório: muitos
times removem ou disfarçam esse cabeçalho em produção pelo mesmo motivo do traceback.

## O que um testador procura

Isto não pede ferramenta além de um navegador e do curl, e cobre boa parte do que um especialista
em segurança levantaria primeiro.

**Páginas de erro.** Entrada errada, uma página que não existe, um número de pedido que não existe:
cada uma deveria responder com uma frase, nunca com as entranhas. Quando se pede um pedido que não
existe, o boxoffice responde do jeito certo:

```
ana@laptop:~$ curl -s 'http://127.0.0.1:8000/order?id=9999' | grep msg
<p class="msg">There is no such order.</p>
```

**HTTPS.** Toda página de um site de verdade deveria carregar por `https`, com o cadeado na barra de
endereço, e digitar o endereço `http` deveria redirecionar para ele. Um formulário que envia uma
senha por `http` simples a envia legível para qualquer um na mesma rede. O boxoffice roda em
`http://127.0.0.1`, o que está certo para um programa que nunca sai do seu notebook; no ambiente de
produção do teatro, `http` simples na página de cadastro seria um defeito da maior gravidade. Isso
não dá para testar no laboratório, então entra no plano como algo a conferir em produção.

**Regras de senha.** O R2 pede de 8 a 64 caracteres e nada mais, então a senha mais fraca do mundo é
aceita:

```
ana@laptop:~$ curl -s -d 'name=Caio&email=caio@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
ana@laptop:~$ curl -s http://127.0.0.1:8000/outbox | grep -c 12345678
0
```

Isso não é um defeito: a aplicação faz o que o R2 diz. É uma **pergunta para o cliente**, a pergunta
de validação da aula 6. As orientações atuais, como as do NIST sobre identidade digital, preferem
comprimento e uma checagem contra listas de senhas que já vazaram a regras sobre símbolos. O
segundo comando acima é uma verificação que vale manter: a caixa de saída guarda o e-mail de
confirmação do Caio e a senha não aparece em lugar nenhum dele, então o `grep -c` conta 0 linhas.
Uma senha devolvida por e-mail seria um defeito.

**O que uma mensagem entrega.** Tente se cadastrar com um endereço que já tem conta:

```
ana@laptop:~$ curl -s -d 'name=Somebody&email=member@example.org&password=long-enough' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
```

A frase ajuda, e também conta a qualquer um que pergunte se um endereço é de um cliente do teatro.
Para um teatro, isso pode ser aceitável; para uma clínica ou um site de namoro, não seria. É uma
troca que cabe ao cliente decidir, e a parte do testador é colocá-la diante dele com a mensagem
exata, do jeito que a aula 12 colocou o desconto de estudante diante da gerente.

## Para onde isto vai

Testadores de segurança trabalham a partir de listas compartilhadas do que dá errado com mais
frequência. A mais conhecida é o **OWASP Top 10**, mantido pela OWASP Foundation, e informação
vazando por mensagens de erro faz parte dela. Para o trabalho além desta seção existem scanners e
proxies de interceptação, usados com permissão, por pessoas treinadas para usá-los. O
`security-fundamentals` e o `non-functional-testing` são os dois cursos desta trilha que os ensinam.
Para um testador manual, o hábito basta: **leia toda página inesperada como um estranho leria, e
pergunte o que ela conta a ele**.
