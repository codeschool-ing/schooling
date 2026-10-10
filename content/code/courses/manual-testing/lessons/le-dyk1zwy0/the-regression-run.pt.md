---
title: A rodada de regressão
version: 1
---

A suíte da seção 03, rodada no boxoffice 1.1 na ordem dos riscos. **Reinicie a aplicação antes de
começar**, para que os números de pedido e os lugares batam com as transcrições, e deixe um segundo
terminal para o curl. Toda requisição abaixo também pode ser feita no navegador, e o texto diz o que
olhar lá.

## A segunda conta

A tabela de desconto precisa de um cliente que não seja sócio. Cadastre Caio Lima,
`caio@example.org`, na página Sign up, com qualquer senha de 8 caracteres ou mais, e não confirme a
conta: uma conta que ninguém confirmou não é de sócio, pelo R5. Depois abra a caixa de saída e
procure o e-mail para ele.

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-1234' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -o 'To: [a-z@.]*'
To: caio@example.org
```

Essa é a linha D da suíte, com as duas verificações passando: a conta existe e o e-mail de
confirmação dela chegou à caixa de saída.

## As regras de preço

Oito reservas para Hamlet, uma por regra da tabela de desconto: Caio ou Bia, dois ingressos ou cinco,
com a caixa Student marcada ou não. O comando guarda só o desconto da página do pedido; no navegador
ele fica na linha acima do total, *Hamlet, 2 ticket(s), 0% off*.

```
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
0% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
0% off
ana@laptop:~/boxoffice$ curl -s -d 'email=caio@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=5&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
15% off
```

Contra o R5, regra por regra. O R5 diz que estudantes pagam metade, o desconto de sócio é 10%, um
pedido de cinco ou mais ganha 15%, e só o maior vale:

| regra | estudante | sócio | 5 ou mais | o R5 diz | a 1.1 deu | veredito |
|---|---|---|---|---|---|---|
| 1 | não | não | não | 0% | 0% | passou |
| 2 | não | não | sim | 15% | 15% | passou |
| 3 | não | sim | não | 10% | 10% | passou |
| 4 | não | sim | sim | 15% | 15% | passou |
| 5 | sim | não | não | 50% | 0% | **falhou** |
| 6 | sim | não | sim | 50% | 15% | **falhou** |
| 7 | sim | sim | não | 50% | 10% | **falhou** |
| 8 | sim | sim | sim | 50% | 15% | **falhou** |

Quatro falhas, e **elas se alinham numa só condição**: toda regra com a caixa Student marcada falha,
e toda regra sem ela passa. Esse padrão é informação por si só. Cada uma das quatro, sozinha, diz
"este estudante pagou o preço errado"; as quatro juntas dizem que a 1.1 ignora a caixa, porque em
todos os casos o desconto é exatamente o que o mesmo cliente ganha sem ela. Quando as falhas se
alinham numa condição assim, essa condição é a primeira coisa que o relatório cita.

Antes de escrever qualquer coisa, a rodada termina. Uma rodada de regressão interrompida na primeira
falha deixa o resto da suíte desconhecido, e a próxima versão precisa da rodada inteira de novo de
qualquer jeito.

## Quantidade, lugares e estados

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=0' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=1' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1009 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1010 reserved.</p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S3&quantity=two' http://127.0.0.1:8000/book
500
```

Zero e sete são recusados, um e seis geram os pedidos 1009 e 1010, tudo como o R4 diz. A última
requisição pede só o código de status, `500`: a página de erro para um campo de ingressos que não é
número, conhecida desde a aula 4 e listada nas notas do Rui. No navegador é a página cheia de Python.

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '[0-9]*</td><td><a href="/book?show=S3'
193</td><td><a href="/book?show=S3
ana@laptop:~/boxoffice$ curl -s -d 'id=1010&action=cancel' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now cancelled.</p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '[0-9]*</td><td><a href="/book?show=S3'
199</td><td><a href="/book?show=S3
```

O número antes do link para S3 na página Shows são os lugares que restam de The Little Prince. Os
pedidos 1009 e 1010 levaram sete dos 200, deixando 193; cancelar o pedido 1010 devolveu os seis
dele, 199. A linha B passa.

```
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=pay' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now paid.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=use' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now used.</p>
ana@laptop:~/boxoffice$ curl -s -d 'id=1009&action=refund' http://127.0.0.1:8000/order | grep msg
<p class="msg">Order is now refunded.</p>
```

Pagar e usar passam. O reembolso de um pedido usado é aceito, o que o R6 não permite: o segundo
defeito conhecido, da aula 5, falhando exatamente como relatado. A rodada registra os dois defeitos
conhecidos como *falha, como relatado* e não abre nada novo para eles.

## É uma regressão?

A seção 02 disse que uma regressão precisa de um antes. A aula 9 guardou o antes: o
`boxoffice-1.0.py`. Suba-o num **terceiro** terminal, em outra porta, para as duas versões rodarem
lado a lado:

```
ana@laptop:~/boxoffice$ BOXOFFICE_PORT=8001 python3 boxoffice-1.0.py
boxoffice 1.0 on http://127.0.0.1:8001  (Ctrl-C stops it)
```

E a mesma requisição, a regra 7, para cada uma, a 1.0 na 8001 e a 1.1 na 8000:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8001/book | grep -o '[0-9]*% off'
50% off
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -o '[0-9]*% off'
10% off
```

Mesmo cliente, mesmo espetáculo, mesmos ingressos, mesma caixa marcada: 50% na 1.0, 10% na 1.1. **O
desconto de estudante funcionava na 1.0 e não funciona na 1.1**, então é uma regressão, trazida por
esta versão. No navegador é a mesma comparação com duas abas, `127.0.0.1:8001` e `127.0.0.1:8000`.
Pare a cópia 1.0 com Ctrl-C quando terminar.

## De onde veio, e até onde dizer

A Ana encontrou isso só pelo comportamento, e o relatório se apoia no comportamento: os passos, os
50% que o R5 e a 1.0 dão, e os 10% que a 1.1 dá. Isso basta para o Rui agir, e o formato do relatório
é assunto da aula 15.

Ela pode dizer mais uma coisa, porque a versão foram três edições que ela mesma aplicou. A aula 9
seção 03 mostra a nova `discount`: a única linha de trabalho dela cita o sócio e o número de
ingressos, e a palavra `student` aparece só na primeira linha, onde a função a recebe. A versão
antiga começava pela regra do estudante. **Um testador pode apontar uma causa provável, marcada como
pista e não como diagnóstico**. "A reescrita de `discount` na 1.1 pode ter deixado cair a regra do
estudante" deixa o Rui confirmar ou corrigir em um minuto, e o relatório continua verdadeiro se a
causa estiver em outro lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" data-fig=\"l10-discount-rules\" aria-label=\"As oito regras da tabela de desconto como colunas. As linhas dizem se o cliente é estudante, sócio, e se reserva cinco ou mais, depois o que o R5 diz e o que a 1.1 deu. As regras 5 a 8, toda regra com estudante, estão contornadas como falhas: o R5 diz 50% e a 1.1 deu 0, 15, 10 e 15. Embaixo, uma linha de marcas mostra que a verificação de sanidade da aula 9 olhou só as regras 3 e 4, e a rodada de regressão da aula 10 olhou as oito.\"><text x=\"164.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">regra</text><rect x=\"181.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"210.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"210.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"210.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"210.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">0%</text><text x=\"210.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0%</text><circle cx=\"210.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"245.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"274.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"274.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"274.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"274.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">15%</text><text x=\"274.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">15%</text><circle cx=\"274.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"309.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"338.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"338.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"338.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"338.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"338.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">10%</text><text x=\"338.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">10%</text><circle cx=\"338.0\" cy=\"206.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"338.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"373.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"402.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"402.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"402.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"402.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">15%</text><text x=\"402.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">15%</text><circle cx=\"402.0\" cy=\"206.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"402.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"437.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"466.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"466.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"466.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"466.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"466.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"466.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0%</text><circle cx=\"466.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"501.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"530.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"530.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"530.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"530.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"530.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"530.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><circle cx=\"530.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"565.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"594.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"594.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"594.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"594.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"594.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"594.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10%</text><circle cx=\"594.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><rect x=\"629.0\" y=\"44.0\" width=\"58.0\" height=\"138.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"658.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"658.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"658.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sim</text><text x=\"658.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">50%</text><text x=\"658.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><circle cx=\"658.0\" cy=\"232.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"164.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estudante</text><text x=\"164.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sócio</text><text x=\"164.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 ou mais</text><text x=\"164.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o R5 diz</text><text x=\"164.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a 1.1 deu</text><text x=\"164.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aula 9, sanidade</text><text x=\"164.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aula 10, regressão</text></svg>", "caption": "A tabela de desconto na 1.1. As quatro regras que falham são exatamente as quatro com estudante, e a verificação de sanidade tinha olhado duas regras sem estudante nenhum."}
```

A verificação de sanidade da aula 9 passou, e estava certa em passar: perguntaram a ela se duas
correções funcionavam, e funcionavam. Ela olhou as regras 3 e 4. A reescrita mexeu nas oito, e as
quatro que ela quebrou são as que ninguém tinha motivo para olhar enquanto conferia uma correção
para sócios. Essa é a distância entre sanidade e regressão, medida numa versão.
