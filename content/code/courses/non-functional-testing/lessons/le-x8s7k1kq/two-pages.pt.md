---
title: Uma página lenta, feita de propósito
version: 1
---

O Lighthouse precisa de uma página para medir, e a bilheteria ainda não tem nenhuma:
`~/boxoffice/static/` está vazio, e o `app.py` serve o que for posto ali. Esta seção escreve duas
páginas que mostram a mesma coisa, a lista de espetáculos à venda sob uma foto do palco. **A
primeira é lenta de quatro jeitos pelos quais páginas reais são lentas, um defeito para cada número
que a próxima seção lê.** A segunda corrige os quatro. Medir as duas é o caminho mais curto para
ver qual número se mexe com qual defeito.

Os quatro defeitos são os comuns, e cada um tem um nome que você vai encontrar num relatório do
Lighthouse:

| defeito | o que custa | o número que mostra |
|---|---|---|
| um script no `<head>` que bloqueia o parser | a página fica em branco enquanto ele roda | First Contentful Paint |
| uma imagem pesada como a maior coisa da tela | o conteúdo principal chega por último | Largest Contentful Paint |
| trabalho na thread principal depois de a página aparecer | toques e teclas esperam | Total Blocking Time |
| conteúdo que se move depois de desenhado | o leitor perde o lugar, ou toca na coisa errada | Cumulative Layout Shift |

## As imagens

Uma imagem de destaque real é uma fotografia, e uma fotografia quase não comprime: a maior parte
dos bytes dela é detalhe. O `make_hero.py` faz o papel de uma sem precisar de câmera nem de
biblioteca de imagens. Ele escreve um PNG de ruído aleatório, que nenhum compressor encolhe, e um
segundo PNG, menor, de um degradê suave, que comprime a quase nada. Só usa a biblioteca padrão,
como o `app.py`. Crie o arquivo em `~/boxoffice` com `nano make_hero.py`:

```python
# boxoffice/make_hero.py
# Draws the two hero pictures the pages in static/ show, with nothing but
# the standard library. The heavy one is noise, which no compressor can
# shrink, the way a photograph barely shrinks; the light one is a gradient.
import os, random, struct, zlib

def png(path, width, height, pixel):
    rows = b"".join(b"\x00" + b"".join(pixel(x, y) for x in range(width))
                    for y in range(height))
    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data)))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(rows, 9)))
        f.write(chunk(b"IEND", b""))
    print(f"{path}: {width}x{height}, {os.path.getsize(path)} bytes")

rnd = random.Random(7)
os.makedirs("static", exist_ok=True)
png("static/hero.png", 1200, 675, lambda x, y: rnd.randbytes(3))
png("static/hero-small.png", 800, 450, lambda x, y: bytes((60 + x // 8, 30 + y // 5, 90)))
```

O formato é curto o bastante para escrever à mão: uma assinatura, um bloco de cabeçalho com o
tamanho, um bloco comprimido com as linhas de pixels e um bloco de fim, cada bloco seguido de uma
soma de verificação. Rode:

```
ana@nft:~/boxoffice$ python3 make_hero.py
static/hero.png: 1200x675, 2431483 bytes
static/hero-small.png: 800x450, 20367 bytes
ana@nft:~/boxoffice$ ls -l static
total 2408
-rw-r--r-- 1 ana ana     950 Oct 10 04:33 fast.html
-rw-rw-r-- 1 ana ana   20367 Oct 10 04:34 hero-small.png
-rw-rw-r-- 1 ana ana 2431483 Oct 10 04:34 hero.png
-rw-r--r-- 1 ana ana    1239 Oct 10 04:33 index.html
-rw-r--r-- 1 ana ana     205 Oct 10 04:33 slow.js
```

**2.431.483 bytes contra 20.367**, para duas imagens que o leitor vê do mesmo tamanho num celular.
A leve também tem menos pixels, 800 de largura contra 1200, porque a coluna da página nunca passa
de 40rem.

## A página lenta

O `slow.js` é o script que bloqueia. Escreva com `nano static/slow.js`:

```javascript
// boxoffice/static/slow.js
// A script in the page's <head> that does nothing useful for 500 ms.
// While it runs, the browser draws nothing.
const until = Date.now() + 500;
while (Date.now() < until) {}
```

Um laço que confere o relógio até passar meio segundo é a forma mais pura de um script que custa
tempo: sem rede, sem trabalho, só a thread principal ocupada. Páginas reais conseguem o mesmo
efeito com um pacote grande de framework, um gerenciador de tags ou um banner de consentimento
carregado do mesmo jeito.

Depois, a página em si, `static/index.html`. As notas ao lado de cada parte dizem qual defeito
ela é; o botão de copiar leva o arquivo inteiro sem elas.

```schooling-example
{"language": "html", "file": "boxoffice/static/index.html", "parts": [{"code": "<!-- boxoffice/static/index.html -->\n<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Box office</title>\n<script src=\"slow.js\"></script>", "note": "O script no `<head>` é o primeiro defeito. Um `<script src>` simples para o parser até o arquivo chegar e rodar, e o navegador não desenha nada antes de o parser alcançar o `<body>`. O `slow.js` gasta 500 ms sem fazer nada, então a página fica em branco pelo menos esse tempo."}, {"code": "<style>\n  body { font-family: sans-serif; margin: 0 auto; max-width: 40rem; padding: 0 1rem; }\n  img { width: 100%; }\n  .banner { background: #fde68a; margin: 0; padding: 3rem 1rem; }\n  li { padding: 0.4rem 0; }\n</style>", "note": "`width: 100%` e nenhuma altura. O navegador não tem como saber a altura da imagem até chegar o bastante do arquivo para ler as dimensões dela, então monta a página com a imagem de altura zero e move tudo o que está abaixo quando descobre."}, {"code": "</head>\n<body>\n<h1>Box office</h1>\n<img src=\"hero.png\" alt=\"The stage, lit for tonight's show\">\n<ul id=\"shows\"><li>Loading the shows...</li></ul>", "note": "O segundo defeito é o `<img>` sem os atributos `width` e `height`, que teriam dito o formato ao navegador antes de chegar um byte do arquivo. O terceiro é o próprio arquivo: `hero.png` é a imagem pesada, com 1200 pixels de largura, desenhada numa coluna de no máximo 40rem."}, {"code": "<script>\n  fetch(\"/shows\").then(r => r.json()).then(shows => {\n    const until = Date.now() + 400;   // 400 ms of work before the list is drawn\n    while (Date.now() < until) {}\n    document.getElementById(\"shows\").innerHTML = shows.map(s =>\n      `<li>${s.title}, ${s.day}: R$ ${(s.price_cents / 100).toFixed(2)}</li>`).join(\"\");\n  });", "note": "A lista chega de `/shows`, e então a página gasta 400 ms de trabalho antes de desenhá-la. Aqui o trabalho é um laço que só espera; numa página real é um framework renderizando, um carrossel se inicializando ou uma biblioteca de analytics analisando. Enquanto ele roda, a página não responde a um toque."}, {"code": "  setTimeout(() => {                  // the promotion arrives a moment later\n    const banner = document.createElement(\"p\");\n    banner.className = \"banner\";\n    banner.textContent = \"Tonight only: two tickets for the price of one.\";\n    document.body.prepend(banner);\n  }, 1000);\n</script>\n</body>\n</html>", "note": "O quarto defeito: uma promoção inserida no alto da página um segundo depois de o resto ter sido desenhado. Tudo o que já estava na tela desce a altura do banner, e é isso que o Cumulative Layout Shift conta."}]}
```

**Nada nela está quebrado no sentido funcional**: a lista chega, os preços estão certos, o banner
diz o que deve. Um teste funcional desta página passa.

## A página corrigida

O `static/fast.html` mantém o mesmo conteúdo e tira os quatro defeitos:

```html
<!-- boxoffice/static/fast.html -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Box office</title>
<style>
  body { font-family: sans-serif; margin: 0 auto; max-width: 40rem; padding: 0 1rem; }
  img { width: 100%; height: auto; }
  .banner { background: #fde68a; margin: 0; padding: 3rem 1rem; }
  li { padding: 0.4rem 0; }
</style>
</head>
<body>
<p class="banner">Tonight only: two tickets for the price of one.</p>
<h1>Box office</h1>
<img src="hero-small.png" width="800" height="450" fetchpriority="high"
     alt="The stage, lit for tonight's show">
<ul id="shows"><li>Loading the shows...</li></ul>
<script>
  fetch("/shows").then(r => r.json()).then(shows => {
    document.getElementById("shows").innerHTML = shows.map(s =>
      `<li>${s.title}, ${s.day}: R$ ${(s.price_cents / 100).toFixed(2)}</li>`).join("");
  });
</script>
</body>
</html>
```

O que mudou, defeito por defeito:

- **Nenhum script bloqueando.** O trabalho do `slow.js` era inútil, então ele saiu. Um script
  necessário levaria `defer`, que deixa o parser seguir e roda o script quando a página termina
  de ser analisada.
- **A imagem leve, com o formato declarado.** `width="800" height="450"` dá ao navegador a
  proporção antes de o arquivo chegar, e `height: auto` na folha de estilos mantém a proporção
  quando a largura é 100%. `fetchpriority="high"` diz ao navegador que esta é a imagem que
  importa.
- **Nenhum trabalho antes de desenhar a lista.** As linhas entram assim que `/shows` responde.
- **O banner está no HTML**, acima do título, então é desenhado junto com o resto e não move nada
  quando aparece.

As duas páginas são servidas pela bilheteria como ela está, do mesmo diretório. Com o servidor
rodando no primeiro terminal, `localhost:8000/` é a página lenta e `localhost:8000/fast.html` a
corrigida.
