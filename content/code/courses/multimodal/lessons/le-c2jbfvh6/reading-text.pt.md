---
title: Lendo texto impresso com o Tesseract
version: 1
---

**O reconhecimento óptico de caracteres (OCR) transforma a imagem de um texto impresso em texto.** O Tesseract é o motor de OCR de código aberto sobre o qual a maioria dos programas que leem texto de imagens é construída, e a versão 5 usa uma pequena rede neural treinada por idioma. Ele faz um trabalho e não finge fazer outros: não vai dizer que uma página é uma nota fiscal nem que o total parece errado.

Ele faz esse trabalho em dois passos, e o primeiro falha mais que o segundo. **Primeiro decide onde está o texto**: quais áreas da página são blocos, quais linhas há neles e em que ordem lê-las. **Depois lê cada linha.** O padrão, o *modo de segmentação de página* 3, supõe que não conhece o layout e o deduz. Na nota do laboratório ele deduziu assim:

```
ana@lab:~/mm$ tesseract media/invoice-0931.png - 2>/dev/null | sed -n "9,20p"
Av. Exemplo 1000, Sao Paulo SP

INVOICE

Number: INV-0931
Date: 2026-09-15
Due: 2026-10-15

Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
```

Todos os caracteres estão certos, menos duas letras (*Sao* e *Bras*, sobre as quais falamos abaixo). Mas o endereço da loja vem antes da palavra INVOICE, que fica no alto da página, e a tabela só saiu inteira porque esta página é limpa. O Tesseract encontrou blocos e leu cada bloco por conta própria, de cima para baixo.

O modo 6 diz a ele para supor **um único bloco uniforme de texto**, lido em linhas:

```
ana@lab:~/mm$ tesseract media/invoice-0931.png - --psm 6 2>/dev/null | sed -n "8,13p"
Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.90 159.00
Subtotal 713.50
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas cópias da tabela da nota vistas pelo Tesseract. À esquerda, o modo de página padrão divide a página em blocos: uma coluna de títulos e, separada, uma coluna de quantidades, preços e valores, então os números saem depois de todos os títulos. À direita, o modo de página 6 trata a página como um só bloco de linhas, e cada título sai na mesma linha dos seus números.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">psm 3, o padrão: blocos</text><rect x=\"20\" y=\"30\" width=\"170\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"200\" y=\"30\" width=\"150\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dom Casmurro</text><text x=\"210\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12  18.50  222.00</text><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Posthumous…</text><text x=\"210\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  21.00  168.00</text><text x=\"30\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bleak House</text><text x=\"210\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  32.90  164.50</text><text x=\"30\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Secret Garden</text><text x=\"210\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10  15.90  159.00</text><text x=\"30\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">bloco 1, lido primeiro</text><text x=\"210\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">bloco 2, lido depois</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">psm 6: um bloco de linhas</text><rect x=\"380\" y=\"36\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dom Casmurro</text><text x=\"560\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12  18.50  222.00</text><rect x=\"380\" y=\"64\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Posthumous…</text><text x=\"560\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  21.00  168.00</text><rect x=\"380\" y=\"92\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bleak House</text><text x=\"560\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  32.90  164.50</text><rect x=\"380\" y=\"120\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Secret Garden</text><text x=\"560\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10  15.90  159.00</text><text x=\"380\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">cada linha lida da esquerda para a direita</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Mesma página, mesmo modelo. Só mudou a suposição sobre o layout: 24,0% dos caracteres errados contra 0,4%.</text></svg>", "caption": "O Tesseract primeiro decide onde está o texto, depois o lê, e a primeira decisão pode ser a que falha."}
```

Num formulário, numa tabela ou numa nota, as linhas são a estrutura que você quer, e dizer isso ao Tesseract é a melhoria mais barata disponível. Os dois modos nas duas cópias da nota, medidos contra a verdade:

```python
"""How far an OCR reading is from the truth: the character error rate, per setting."""
import subprocess
import sys

import jiwer

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())


def read(path, psm, lang):
    out = subprocess.run(["tesseract", path, "-", "--psm", psm, "-l", lang],
                         capture_output=True, text=True, check=True).stdout
    return " ".join(out.split())


for path in sys.argv[1:]:
    for psm, lang in (("3", "eng"), ("6", "eng"), ("6", "eng+por")):
        cer = jiwer.cer(TRUTH, read(path, psm, lang))
        print(f"{path:28} psm {psm}  {lang:8} CER {cer:6.1%}")
```

```
ana@lab:~/mm$ python score.py media/invoice-0931.png media/invoice-0931-scan.jpg
media/invoice-0931.png       psm 3  eng      CER  24.0%
media/invoice-0931.png       psm 6  eng      CER   0.4%
media/invoice-0931.png       psm 6  eng+por  CER   0.4%
media/invoice-0931-scan.jpg  psm 3  eng      CER  57.1%
media/invoice-0931-scan.jpg  psm 6  eng      CER   1.2%
media/invoice-0931-scan.jpg  psm 6  eng+por  CER   0.4%
```

Três achados, em ordem de tamanho.

**Escolher o modo de página moveu o erro de 24,0% para 0,4%** na página limpa e de 57,1% para 1,2% no escaneado. Quase todo o "erro" do modo 3 é texto na ordem errada, que uma pessoa ignora ao ler e um programa que separa linhas não ignora.

**Os dados de idioma importam para os caracteres que eles conhecem.** O `eng` não tem *ã* nem *á*, então *São Paulo* e *Brás Cubas* saíram como *Sao* e *Bras*. Acrescentar o português (`-l eng+por`, o pacote `tesseract-ocr-por`, que o laboratório instala) consertou os dois no escaneado. Uma nota de um fornecedor brasileiro com títulos em inglês precisa dos dois idiomas.

**A página limpa não é o escaneado.** A próxima seção trata da diferença.
