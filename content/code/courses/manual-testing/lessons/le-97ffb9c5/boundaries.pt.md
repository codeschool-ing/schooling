---
title: Valores de fronteira
version: 1
---

**Defeitos se juntam nas bordas das partições, não no meio delas.** Um requisito diz "de 1 a 40";
alguém transforma isso em código e precisa decidir, caractere por caractere, se o 40 está dentro ou
fora. Escrever "menor que" onde se queria "menor ou igual" move a borda em um, e todo valor no meio
da partição continua se comportando. Um representante de 20 caracteres passa nas duas versões do
código. Só um valor na borda consegue distingui-las.

A **análise de valor limite** é a técnica que vai até lá. Ela pega as partições da seção 02 desta
aula e, em vez de um valor do meio de cada uma, testa os valores dos dois lados de cada linha entre
elas. Ela não substitui o particionamento; é traçada por cima dele, e sem as partições não há
linhas para onde ir.

## Que valores ficam na fronteira

Um **valor de fronteira** é o menor ou o maior valor de uma partição. As partições do nome no R2 se
encontram em duas linhas, uma entre 0 e 1 caractere e outra entre 40 e 41, então os valores de
fronteira são 0, 1, 40 e 41. Duas convenções dizem quantos deles testar em volta de cada linha:

- a análise de **dois valores** testa o valor na fronteira e o vizinho mais próximo do outro lado
  da linha: para o nome, 0 e 1, e 40 e 41. Quatro casos;
- a análise de **três valores** acrescenta também o vizinho mais próximo do lado de dentro: 2 e 39.
  Seis casos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" data-fig=\"l04-boundary\" aria-label=\"Uma reta de tamanhos de nome: 0, 1 e 2, uma quebra, depois 39, 40 e 41. Ao fundo, as partições vazio, 1 a 40 caracteres e 41 ou mais. Linhas tracejadas marcam as duas fronteiras, entre 0 e 1 e entre 40 e 41. Os valores 0, 1, 40 e 41 são círculos cheios, os valores de fronteira da análise de dois valores; 2 e 39 são círculos vazados, os que a análise de três valores acrescenta.\"><rect x=\"112.0\" y=\"52.0\" width=\"66.0\" height=\"110.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">vazio</text><rect x=\"182.0\" y=\"52.0\" width=\"296.0\" height=\"110.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">1 a 40 caracteres</text><rect x=\"482.0\" y=\"52.0\" width=\"76.0\" height=\"110.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">41 ou mais</text><path d=\"M118.0 130.0 L172.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M188.0 130.0 L320.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M340.0 130.0 L472.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M488.0 130.0 L552.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">…</text><path d=\"M180.0 34.0 L180.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"180.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fronteira</text><path d=\"M480.0 34.0 L480.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"480.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fronteira</text><circle cx=\"150.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"150.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><circle cx=\"210.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"210.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><circle cx=\"270.0\" cy=\"130.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"270.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><circle cx=\"390.0\" cy=\"130.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"390.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">39</text><circle cx=\"450.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"450.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">40</text><circle cx=\"510.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"510.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">41</text><text x=\"330.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caracteres no nome</text><circle cx=\"130.0\" cy=\"222.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"144.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois valores: 0, 1, 40 e 41</text><circle cx=\"390.0\" cy=\"222.0\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"404.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">três valores: mais 2 e 39</text></svg>", "caption": "As fronteiras do tamanho do nome no R2. A análise de dois valores testa os quatro valores cheios, um de cada lado de cada linha; a de três valores acrescenta os vazados, o valor seguinte do lado de dentro."}
```

Dois valores bastam para a maioria dos campos, e são o que este curso usa. O terceiro valor
compensa o custo quando a linha é traçada por uma expressão e não por uma comparação simples, como
um limite calculado a partir de outra coisa, em que um erro pode mover a borda em mais de um. Num
limite fixo como 40 ele raramente acha o que os dois primeiros deixaram passar.

"Vizinho mais próximo" depende do que o campo guarda. Para uma contagem de caracteres ou de
ingressos, é um a mais ou um a menos. Para dinheiro, é um centavo: um vale "de até R$ 100,00" tem
a linha entre R$ 100,00 e R$ 100,01. Para um horário, é o menor passo que o sistema guarda, um
minuto ou um segundo. A linha do "a reserva fecha uma hora antes do início" do R4 cai às
19:00 para um espetáculo às 20:00, e os casos ficam um minuto de cada lado dela. Esse precisa do
relógio movido para ser testado, e a aula 13 mostra como um relógio falso faz isso.

## Rodando as fronteiras do R2

O R2 tem duas regras de tamanho, então a análise de dois valores dá oito valores: 0, 1, 40 e 41
caracteres para o nome, e 7, 8, 64 e 65 para a senha. Cada um roda como um cadastro com todo o
resto válido, para que a única coisa que possa dar errado seja o valor em teste, e cada um precisa
de um endereço de e-mail próprio, porque um endereço que funcionou uma vez está ocupado na segunda.

No navegador, abra **Sign up**, digite os valores nos três campos e aperte **Create account**: a
frase no alto da página que volta é o resultado. Textos de 40 ou 65 caracteres saem certos mais
facilmente quando você não os inventa: as transcrições usam algarismos, `1234567890` repetido, para
que o tamanho possa ser contado de dez em dez. No terminal, com o boxoffice recém-iniciado:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=&email=n0@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Name must be 1 to 40 characters.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s -d 'name=A&email=n1@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to n1@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=1234567890123456789012345678901234567890&email=n40@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to n40@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=12345678901234567890123456789012345678901&email=n41@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Name must be 1 to 40 characters.</p><form method="post" action="/signup">
```

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p7@example.org&password=1234567' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Password must be 8 to 64 characters.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p8@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to p8@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p64@example.org&password=1234567890123456789012345678901234567890123456789012345678901234' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to p64@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p65@example.org&password=12345678901234567890123456789012345678901234567890123456789012345' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Password must be 8 to 64 characters.</p><form method="post" action="/signup">
```

Os oito se comportam. O nome vazio e o de 41 caracteres recebem a frase que o R2 e o R7 pedem; um e
40 caracteres criam uma conta; a senha é recusada com 7 e 65 e aceita com 8 e 64. **Um teste de
fronteira que passa é um resultado, não um desperdício.** Antes de esses oito rodarem, ninguém sabia
onde o boxoffice traçava essas quatro linhas; agora há evidência de que ele as traça onde o R2
traça. Isso merece registro exatamente como uma falha, com os valores usados e o que voltou.

## Fronteiras que o requisito não escreve

Algumas linhas não estão nos números do requisito. O "enquanto houver lugar" do R4 é uma fronteira
que se move: fica entre os lugares restantes e um a mais que isso, e está em outro ponto depois de
cada reserva. Um teatro com 200 lugares para The Little Prince não precisa de 200 reservas para
chegar a ela, só de um momento em que restem poucos. Outras linhas vêm da plataforma e não da regra:
um campo guardado numa coluna de 255 caracteres tem uma fronteira em 255, diga o requisito o que
disser. **Perguntar a um desenvolvedor "existe algum limite aqui que eu não vejo?" faz parte da
técnica**, e a resposta muitas vezes acrescenta uma linha ao desenho.

A seção 04 desta aula leva as duas técnicas ao campo de quantidade do R4, onde um dos quatro valores
de fronteira não se comporta.
