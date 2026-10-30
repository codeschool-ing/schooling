---
title: O dp do Android, os cinco buckets e o sp para texto
version: 1
---

**No Android, um dp é um pixel numa tela de 160 pontos por polegada, e toda outra densidade é um
múltiplo disso.** A documentação do Android sobre densidades de tela dá a conversão numa linha:

```
px = dp * (dpi / 160)
```

Então numa tela de 320 dpi um dp são dois pixels, e numa de 480 dpi são três. A mesma página traz
um aviso que vale guardar: um app não deve escrever essa conta no próprio código, porque a
plataforma tem uma função que a faz, `TypedValue.applyDimension()`, e o Compose a faz por você
sempre que um tamanho é escrito como `48.dp`.

## Os buckets

**As telas são separadas em buckets de densidade, e cada bucket tem um nome que aparece em nomes de
pastas.** A tabela de qualificadores de densidade da documentação lista estes, cada um com um dpi
aproximado:

| bucket | cerca de | escala em relação ao mdpi | o que a documentação diz dele |
|---|---|---|---|
| `ldpi` | 120 dpi | 0,75x | densidade baixa |
| `mdpi` | 160 dpi | 1x | densidade média, a referência |
| `hdpi` | 240 dpi | 1,5x | densidade alta |
| `xhdpi` | 320 dpi | 2x | densidade extra-alta |
| `xxhdpi` | 480 dpi | 3x | densidade extra-extra-alta |
| `xxxhdpi` | 640 dpi | 4x | densidade extra-extra-extra-alta |

A documentação resume a escada como uma proporção, 3:4:6:8:12:16 entre as seis, que é a mesma
coluna de escalas multiplicada por quatro. **Uma tela real quase nunca cai exatamente num degrau.**
Um celular de 420 dpi não está em bucket nenhum; o sistema usa a densidade verdadeira dele para
converter dp em pixels, e escolhe o bucket mais próximo só quando precisa escolher um arquivo de
imagem, ponto ao qual a última seção desta aula volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l07-buckets\" aria-label=\"Cinco quadrados lado a lado, desenhados em escala, em pixels: os arquivos de um ícone de 24 dp. mdpi de 160 dpi tem 24 por 24 pixels, escala 1x; hdpi de 240 dpi tem 36 por 36, 1,5x; xhdpi de 320 dpi tem 48 por 48, 2x; xxhdpi de 480 dpi tem 72 por 72, 3x; xxxhdpi de 640 dpi tem 96 por 96, 4x.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um ícone de 24 dp como arquivo raster por bucket, em escala</text><rect x=\"60\" y=\"126\" width=\"24\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">24 x 24</text><text x=\"72.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mdpi</text><text x=\"72.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">160 dpi</text><text x=\"72.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1x</text><rect x=\"180\" y=\"114\" width=\"36\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"198.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">36 x 36</text><text x=\"198.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hdpi</text><text x=\"198.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">240 dpi</text><text x=\"198.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,5x</text><rect x=\"300\" y=\"102\" width=\"48\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"324.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">48 x 48</text><text x=\"324.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xhdpi</text><text x=\"324.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">320 dpi</text><text x=\"324.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2x</text><rect x=\"420\" y=\"78\" width=\"72\" height=\"72\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"456.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">72 x 72</text><text x=\"456.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xxhdpi</text><text x=\"456.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">480 dpi</text><text x=\"456.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3x</text><rect x=\"542\" y=\"54\" width=\"96\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">96 x 96</text><text x=\"590.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xxxhdpi</text><text x=\"590.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">640 dpi</text><text x=\"590.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4x</text></svg>", "caption": "Os buckets do Android como uma escada. Cada degrau é uma pasta com a própria cópia da imagem, e a maior cópia tem dezesseis vezes os pixels da menor.", "same": ["160 dpi", "240 dpi", "320 dpi", "480 dpi", "640 dpi", "1x", "2x", "3x", "4x"]}
```

## O texto tem unidade própria: sp

Um tamanho de layout em dp fica igual quando o usuário pede texto maior, e isso é certo para o
espaço entre dois botões. É errado para o texto dentro deles. **Para texto, o Android tem o
scalable pixel, `sp`**: do mesmo tamanho de um dp por padrão, mas ele cresce e diminui com o
tamanho de texto preferido do usuário. A documentação do Android traça a linha em duas frases: use
sp para tamanhos de texto, e nunca use sp para tamanhos de layout.

| escreva isto em | dp | sp |
|---|---|---|
| a altura de um botão, uma margem, um ícone | sim | não: o layout cresceria quando só as palavras deveriam |
| o tamanho do título de uma sessão | não: ignoraria a configuração de texto do usuário | sim |

A consequência cai no layout. Uma linha de 48 dp de altura com texto em sp vai bem no tamanho de
texto padrão e corta o texto quando o usuário o dobra, então uma linha que contém texto precisa
poder crescer. **Esse é o primeiro ponto em que esta aula toca a aula 19**, e os trechos da próxima
seção mostram a mesma divisão no iOS e no React Native.

Nenhuma das duas unidades é uma promessa em milímetros. "Mais ou menos o mesmo tamanho físico" é o
projeto, e um dp em dois celulares do mesmo bucket ainda pode diferir um pouco, porque a densidade
verdadeira de cada tela não é exatamente o número do bucket. O que o dp remove é o fator de três ou
quatro entre uma tela de baixa densidade e uma de alta, que é a diferença que o dedo do usuário
percebe.
