---
title: A página de reserva
version: 1
---

As quatro aulas deste terço auditam uma página e a consertam. **É a página de reserva da
bilheteria, e ela é mal escrita de propósito**: oito defeitos do tipo que uma equipe de verdade
entrega toda semana, cada um invisível para quem usa mouse e enxerga a tela. É HTML simples com um
script pequeno, e a bilheteria da aula 1 a serve: o `app.py` entrega qualquer arquivo dentro de
`~/boxoffice/static/`, e o script da página conversa com os mesmos `/shows` e `/bookings` que os
testes de carga usaram.

Crie a pasta e abra o primeiro arquivo:

```sh
mkdir -p ~/boxoffice/static && cd ~/boxoffice/static
nano logo.svg
```

O logo é a imagem de uma palavra, o que importa daqui a pouco:

```xml
<!-- boxoffice/static/logo.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="48" viewBox="0 0 200 48">
  <rect width="200" height="48" rx="6" fill="#7a1f2b"/>
  <text x="100" y="31" font-size="20" font-weight="bold" fill="#fff"
        text-anchor="middle">boxoffice</text>
</svg>
```

Depois `nano book.html`, e a página em si. O botão de copiar leva o arquivo inteiro sem as notas,
e as notas nomeiam cada defeito com o critério de sucesso em que ele reprova.

```schooling-example
{"language": "html", "file": "boxoffice/static/book.html", "parts": [{"code": "<!-- boxoffice/static/book.html -->\n<!doctype html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Book a seat</title>", "note": "O cabeçalho de uma página comum, com título e viewport. **Defeito 1**: `<html>` não tem `lang`, então um leitor de tela adivinha em que idioma falar a página, e adivinha pelas configurações do próprio usuário (3.1.1 Idioma da página, A)."}, {"code": "<style>\n  body { font-family: sans-serif; max-width: 36rem; margin: 2rem auto; color: #222; }\n  nav a { margin-right: 1rem; color: #7a1f2b; }\n  .note { color: #999; }\n  *:focus { outline: none; }\n  .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;\n          cursor: pointer; }\n  .wrong { border: 2px solid #d00; }\n</style>", "note": "**Defeito 2**: a nota é `#999` sobre branco, um cinza claro que parece elegante e é difícil de ler (1.4.3 Contraste, AA). **Defeito 3**: `*:focus { outline: none; }` apaga o contorno que mostra qual controle está com o teclado (2.4.7 Foco visível, AA). `.wrong` é a borda vermelha que o script põe num campo deixado vazio."}, {"code": "</head>\n<body>\n<img src=\"logo.svg\" width=\"200\" height=\"48\">\n<nav><a href=\"/shows\">What's on</a> <a href=\"/prices\">Prices</a> <a href=\"/access\">Access</a></nav>\n<h1>Book a seat</h1>\n<p class=\"note\">Seats are held for ten minutes. The price includes the booking fee.</p>", "note": "**Defeito 4**: o logo é uma imagem sem `alt`, e o conteúdo dela é só uma palavra (1.1.1 Conteúdo não textual, A). Os três links levam a páginas que esta bilheteria pequena não tem; estão ali porque um cabeçalho de verdade tem links, e a aula 14 passa por eles com Tab."}, {"code": "<form id=\"book\">\n  <p><label for=\"show\">Show</label><br><select id=\"show\"></select></p>\n  <p><label for=\"seat\">Seat</label><br><input id=\"seat\" type=\"number\" min=\"1\" max=\"300\" value=\"1\"></p>\n  <p>Your name<br><input id=\"customer\" tabindex=\"1\"></p>\n  <div class=\"book\" onclick=\"book()\">Book</div>\n</form>\n<p id=\"result\"></p>", "note": "**Defeito 5**: \"Your name\" é texto ao lado do campo, não um `<label>` ligado a ele, então o campo não tem nome (1.3.1 Informações e relações, 4.1.2 Nome, função, valor, ambos A). **Defeito 6**: `tabindex=\"1\"` manda o teclado para esse campo antes de qualquer outra coisa da página (2.4.3 Ordem do foco, A). **Defeito 7**: Book é uma `<div>` com tratador de clique. Parece um botão e responde ao mouse, mas não recebe o foco e não tem papel (2.1.1 Teclado, 4.1.2, ambos A)."}, {"code": "<script>\nfetch(\"/shows\").then(r => r.json()).then(shows => {\n  for (const s of shows) document.getElementById(\"show\").add(new Option(`${s.title}, ${s.day}`, s.id));\n});\nasync function book() {\n  const name = document.getElementById(\"customer\");\n  name.classList.toggle(\"wrong\", name.value.trim() === \"\");\n  if (name.value.trim() === \"\") return;\n  const answer = await fetch(\"/bookings\", { method: \"POST\", body: JSON.stringify({\n    show_id: document.getElementById(\"show\").value,\n    seat: document.getElementById(\"seat\").value, customer: name.value }) });\n  const body = await answer.json();\n  document.getElementById(\"result\").textContent =\n    answer.ok ? `Booked: seat ${body.seat}, booking ${body.id}.` : `Not booked: ${body.error}.`;\n}\n</script>\n</body>\n</html>", "note": "O script preenche a lista de espetáculos a partir de `/shows` e manda a reserva para `POST /bookings`, o mesmo endpoint que a aula 1 testou com `curl`. **Defeito 8**: um nome vazio deixa a borda do campo vermelha e não diz mais nada, então o erro existe só como cor (1.4.1 Uso de cor, 3.3.1 Identificação de erro, ambos A)."}]}
```

## Servindo a página

Suba a bilheteria como a aula 1 faz, a partir de `~/boxoffice`, num terminal só para ela:

```sh
cd ~/boxoffice && python3 seed.py && python3 app.py
```

O banco novo importa para as aulas 14 e 15, cujos scripts reservam assentos específicos. No
segundo terminal, peça os dois arquivos. `-D -` imprime os cabeçalhos e `-o /dev/null` joga o
corpo fora; `curl -I` mandaria uma requisição `HEAD`, que este servidor pequeno não responde.

```
ana@nft:~/boxoffice$ curl -s -D - -o /dev/null localhost:8000/book.html
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:42:35 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1907
Server-Timing: db;dur=0.0, pay;dur=0.0, total;dur=1.0

ana@nft:~/boxoffice$ curl -s -D - -o /dev/null localhost:8000/logo.svg
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:42:35 GMT
Content-Type: image/svg+xml
Content-Length: 299
Server-Timing: db;dur=0.0, pay;dur=0.0, total;dur=0.6
```

A página chega como `text/html` e o logo como `image/svg+xml`, os dois tipos que o `app.py`
conhece para esses sufixos. Para ver a página no seu próprio navegador, reinicie o servidor com
`BOXOFFICE_HOST=0.0.0.0` como a aula 1 explica e abra `book.html` no endereço da VM. Ela parece
ótima. A questão é justamente essa: **todo defeito da lista é um defeito para outra pessoa.**

## Os oito defeitos

| | defeito | quem o encontra | critério |
|---|---|---|---|
| 1 | sem `lang` no `<html>` | quem usa leitor de tela, cujo leitor pode falar texto em inglês com regras do português | 3.1.1 (A) |
| 2 | nota cinza, `#999` sobre branco | quem tem baixa visão, ou está com o celular no sol | 1.4.3 (AA) |
| 3 | contorno de foco removido | todo usuário de teclado, que deixa de ver onde está | 2.4.7 (AA) |
| 4 | logo sem `alt` | quem usa leitor de tela, que ouve um nome de arquivo ou nada | 1.1.1 (A) |
| 5 | campo de nome sem rótulo | quem usa leitor de tela, que chega a um campo de texto sem nome e sem pergunta | 1.3.1, 4.1.2 (A) |
| 6 | `tabindex="1"` | quem usa teclado, mandado primeiro para o fim do formulário | 2.4.3 (A) |
| 7 | Book é uma `<div>` | todo mundo sem mouse: não há como apertá-lo | 2.1.1, 4.1.2 (A) |
| 8 | erro mostrado só como borda vermelha | quem não vê o vermelho como vermelho, e todo usuário de leitor de tela | 1.4.1, 3.3.1 (A) |

Seis dos oito são de nível A, o piso. **Nenhum deles quebra a página para quem a escreveu**, e por
isso nenhum é pego por um teste funcional: o assento é reservado quando o autor clica em Book. A
aula 13 entrega a página às ferramentas automáticas e conta quantos dos oito elas acham.
