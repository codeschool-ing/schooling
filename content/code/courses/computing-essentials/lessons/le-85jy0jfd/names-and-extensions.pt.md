---
title: A extensão é uma pista, e a pista pode mentir
version: 1
---

As letras depois do último ponto no nome de um arquivo são a **extensão** dele, e o sistema
operacional as usa para decidir qual programa abre o arquivo e qual ícone desenhar.

Esse é o mecanismo inteiro, e a metade importante é o que ele **não** é: a extensão não é o tipo
do arquivo. É um rótulo escrito no nome, pode ser mudado por qualquer um com direito de renomear,
e mudá-la não converte nada.

Renomeie `photo.jpg` para `photo.txt` e você tem um editor de texto te mostrando garatujas.
Renomeie de volta e é uma fotografia de novo. Nada nos bytes se mexeu.

## O truque que decorre disso

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas caixas. A de cima está rotulada como o que o gerenciador de arquivos mostra e traz invoice.pdf, descrito como um documento. A de baixo está rotulada como o que o nome de fato é e traz invoice.pdf.exe, com o ponto e x e destacado em outra cor e descrito como a única parte que decide o que abrir aquilo faz.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">O mesmo arquivo, mostrado e nomeado</text><rect x=\"24\" y=\"52\" width=\"672\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o gerenciador de arquivos te mostra</text><text x=\"44\" y=\"98\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">invoice.pdf</text><text x=\"676\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e ele desenha um ícone de documento ao lado</text><rect x=\"24\" y=\"140\" width=\"672\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"44\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o nome de fato é</text><text x=\"44\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">invoice.pdf</text><text x=\"130\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">.exe</text><text x=\"676\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">e é esta a única parte que decide</text><text x=\"24\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Esconder a última extensão é o padrão no Windows, e esse padrão é o truque inteiro.</text></svg>", "caption": "Nada foi falsificado. O nome sempre foi esse; um ajuste decidiu quanto dele te mostraram."}
```

O Windows esconde a extensão dos tipos conhecidos por padrão, então um arquivo chamado
`invoice.pdf.exe` é exibido como `invoice.pdf`. O ícone pode ser definido como documento por quem
o fez. Tudo que uma pessoa consegue ver diz *documento* e as três últimas letras dizem
*programa*.

**Desligue o esconder extensões.** É uma caixa de seleção — *Extensões de nomes de arquivos* no
menu Exibir do Explorador — e é o ajuste de segurança mais útil de uma máquina doméstica, porque
torna a classe inteira de ataque visível em vez de invisível.

Duas coisas relacionadas que valem saber:

- **Um `.zip` contendo um `.exe`** é a entrega comum, porque a extensão fica escondida dentro do
  arquivo compactado também, até ser extraída.
- **O ícone faz parte do arquivo**, escolhido por quem o construiu. Um ícone não prova nada.

## Para que a extensão serve

Para quase tudo, quase sempre. É uma convenção que funciona porque as pessoas em geral não
mentem, e as alternativas são piores: macOS e Linux conseguem inspecionar os primeiros bytes de
um arquivo para adivinhar o tipo real, o que é mais honesto e mais lento, e os dois ainda usam a
extensão como primeira resposta.

| | o que significa |
|---|---|
| `.pdf`, `.docx`, `.xlsx` | documentos. Os dois últimos são arquivos zip cheios de XML |
| `.jpg`, `.png`, `.webp` | imagens. O `.png` mantém bordas nítidas, o `.jpg` mantém fotos pequenas |
| `.mp4`, `.mkv` | *recipientes* de vídeo, que nada dizem sobre o codec lá dentro |
| `.zip`, `.7z`, `.tar.gz` | arquivos compactados. Vários arquivos em um |
| `.exe`, `.msi`, `.bat`, `.cmd` | coisas que executam. Trate os quatro do mesmo jeito |
| `.txt`, `.csv`, `.json`, `.md` | texto puro, legível em qualquer editor |

## As regras de um nome que nunca dá problema

- **Nada de `\ / : * ? " < > |`.** O Windows os proíbe porque significam algo para o sistema.
- **Espaços são legais e levemente chatos.** Funcionam em todo lugar e precisam de aspas sempre
  que um nome chega a uma linha de comando. Um hífen ou um sublinhado nunca precisa.
- **Acentos e `ç` estão bem hoje** e não estavam dez anos atrás. O único lugar em que ainda dão
  problema é um arquivo viajando para um sistema muito antigo ou para um servidor mal escrito.
- **Curto o bastante para ler.** O Windows tem um limite de caminho perto de 260 caracteres que
  ainda aparece em lugares estranhos, e ele conta as pastas também.
- **Nunca termine um nome com espaço ou ponto.** O Windows os remove silenciosamente, o que
  significa que o arquivo que você cria não é o arquivo que você nomeou.
