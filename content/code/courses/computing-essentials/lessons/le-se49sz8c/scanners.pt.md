---
title: Scanners, e o número de resolução que não é uma medição
version: 1
---

Um scanner é um monitor ao contrário. Uma barra carregando uma lâmpada e uma fileira de sensores
percorre o comprimento do vidro, lendo uma faixa fina da página por vez, e as faixas são
empilhadas numa imagem. A tampa não é uma capa; é um fundo branco que impede a sala de aparecer
no seu escaneamento.

## A resolução óptica é a de verdade

Um scanner anuncia duas resoluções e só uma delas é um fato.

- **Resolução óptica** — `600 × 1200 dpi`, digamos — é quantos sensores existem fisicamente por
  polegada ao longo da barra, e em quantas faixas por polegada a barra para enquanto percorre.
  Essa é medida.
- **Interpolada** — `9600 dpi` na mesma caixa — é software inventando pixels entre os que foram
  de fato lidos. Faz um arquivo maior com a mesma informação.

**Interpolação nunca é mais detalhe.** Se uma caixa dá um número grande e um pequeno, o pequeno é
o scanner.

## Qual resolução você realmente quer

Mais também não é melhor aqui, porque um escaneamento no dobro da resolução é quatro vezes o
arquivo e quatro vezes a espera, por um detalhe que ninguém vai olhar.

| o que você está escaneando | resolução sensata | por quê |
|---|---|---|
| um documento para ler ou mandar por e-mail | 200–300 dpi | acima de 300 você guarda a textura do papel |
| um documento para reconhecimento de texto | 300 dpi | é para o que quase todo OCR está afinado |
| uma fotografia para guardar | 600 dpi | grão, e espaço para recortar |
| uma fotografia para ampliar | 1200 dpi | a única razão honesta para subir |
| um slide ou negativo de 35 mm | 2400 dpi para cima | o original é minúsculo, então cada polegada conta |

`300 dpi` cobre a maior parte de uma vida. O hábito de escanear tudo no máximo produz uma pasta
de arquivos enormes que demoram mais para abrir, mais para enviar, e não são mais legíveis.

## O OCR, e o que ele está de fato fazendo

**Reconhecimento óptico de caracteres** transforma a imagem de uma página em texto que dá para
buscar e copiar. Um escaneamento sem ele é uma fotografia de palavras — você consegue ler e o
computador não.

Duas coisas decidem se funciona: a resolução (300 dpi é o piso) e se a página está reta. É muito
melhor do que já foi em texto impresso e continua ruim em letra de mão, e ele inventa
silenciosamente palavras plausíveis quando erra, que é o modo de falha a vigiar. **Um erro de OCR
não parece um erro.**

## Profundidade de cor, e os três modos

- **Preto e branco**, um bit por pixel — para traço e formulários. Arquivos minúsculos, cinza
  nenhum.
- **Tons de cinza**, 8 bits — a escolha certa para quase todo documento de texto.
- **Cor**, 24 bits — para qualquer coisa em que a cor seja informação.

Escanear uma página datilografada em cor triplica o arquivo para registrar que o papel está
levemente amarelado.

## Mesa, alimentado por folhas, e o telefone no seu bolso

Um scanner **de mesa** escaneia qualquer coisa que você consiga deitar, inclusive um livro. Um
scanner **alimentado por folhas** ou o alimentador de um multifuncional puxa as páginas e é muito
mais rápido para uma pilha, e não aceita um livro nem um original frágil.

E, honestamente: **a câmera de um celular com um aplicativo de documentos ganha de um scanner de
mesa para uma página só.** Ela corrige a perspectiva, acha as bordas, limpa para branco e roda o
OCR no tempo em que uma lâmpada esquenta. O scanner ganha numa pilha, num livro, e em qualquer
coisa cujo original precise ser reproduzido em vez de lido.

## Multifuncionais, e o único aviso honesto

Impressora, scanner e copiadora numa caixa só é genuinamente conveniente e tem uma propriedade
que vale conhecer antes de depender dela: **é um aparelho só, então ele falha como um só.** Uma
cabeça de impressão entupida ou um cartucho vazio bastam para vários modelos se recusarem a
escanear também, o que é uma fila de conserto de um para dois serviços que você achava separados.
