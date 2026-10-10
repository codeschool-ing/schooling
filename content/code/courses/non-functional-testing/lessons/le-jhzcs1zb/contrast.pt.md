---
title: Contraste, calculado
version: 1
---

A maioria dos defeitos de acessibilidade é um sim ou um não: a imagem tem alternativa em texto ou
não tem. O contraste é um número, e **o número é calculado a partir das duas cores, nunca julgado a
olho**. O monitor da designer, a luz da sala e os olhos de quem testa mudam o que parece legível; a
razão não muda. É também a falha mais comum que existe. A pesquisa anual da WebAIM nas páginas
iniciais do milhão de sites mais visitados encontra texto de baixo contraste na maioria delas, ano
após ano, e é o defeito que a ferramenta da aula 13 lista primeiro.

## A fórmula, como programa

A WCAG define a razão em dois passos, e vinte linhas de Python bastam para os dois. Crie a pasta
que a aula 13 usa e abra o arquivo:

```sh
mkdir -p ~/a11y && cd ~/a11y
nano contrast.py
```

```schooling-example
{"language": "python", "file": "a11y/contrast.py", "parts": [{"code": "# a11y/contrast.py\n# The contrast ratio between two colours, the way WCAG 2.2 defines it.\n#   python3 contrast.py 999999 ffffff\nimport sys", "note": "Uma pasta própria, `~/a11y`, que a aula 13 transforma num projeto Playwright. As duas cores entram em hexadecimal, com ou sem o `#`."}, {"code": "\ndef luminance(colour):\n    channels = [int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4)]\n    r, g, b = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4\n               for c in channels]\n    return 0.2126 * r + 0.7152 * g + 0.0722 * b", "note": "**A luminância relativa** é o quanto uma cor parece clara, de 0 para o preto a 1 para o branco. Cada canal sai da codificação da tela de volta para luz, e depois recebe um peso: o verde conta dez vezes mais que o azul, porque o olho é muito mais sensível a ele. As constantes são as que a WCAG 2.2 dá na definição."}, {"code": "\ndef ratio(first, second):\n    light, dark = sorted((luminance(first), luminance(second)), reverse=True)\n    return (light + 0.05) / (dark + 0.05)", "note": "**A razão** é a luminância mais clara mais 0.05 sobre a mais escura mais 0.05. O 0.05 representa a luz que uma tela de verdade reflete, e é por isso que preto no branco dá 21:1 e não infinito. A ordem dos argumentos não importa."}, {"code": "\ntext, background = sys.argv[1].lstrip(\"#\"), sys.argv[2].lstrip(\"#\")\nr = ratio(text, background)\nmarks = [f\"{name} {'yes' if r >= need else 'no'}\"\n         for name, need in ((\"AA text\", 4.5), (\"AA large\", 3), (\"AAA text\", 7))]\nprint(f\"#{text} on #{background}: {r:.2f}:1   \" + \", \".join(marks))", "note": "Três limites, de três critérios: 4.5:1 para texto no AA (1.4.3), 3:1 para texto grande no AA, que também é o que o 1.4.11 pede das partes de um controle, e 7:1 para texto no AAA (1.4.6)."}]}
```

Rode-o nas cores que o `book.html` usa: a nota cinza, um substituto para ela, o texto branco do
controle Book sobre o vermelho-escuro, o vermelho da borda de erro e o texto do corpo.

```
ana@nft:~/a11y$ python3 contrast.py 999999 ffffff
#999999 on #ffffff: 2.85:1   AA text no, AA large no, AAA text no
ana@nft:~/a11y$ python3 contrast.py 767676 ffffff
#767676 on #ffffff: 4.54:1   AA text yes, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py 777777 ffffff
#777777 on #ffffff: 4.48:1   AA text no, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py ffffff 7a1f2b
#ffffff on #7a1f2b: 10.20:1   AA text yes, AA large yes, AAA text yes
ana@nft:~/a11y$ python3 contrast.py dd0000 ffffff
#dd0000 on #ffffff: 5.15:1   AA text yes, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py 222222 ffffff
#222222 on #ffffff: 15.91:1   AA text yes, AA large yes, AAA text yes
```

**A nota reprova com 2.85:1**, bem abaixo dos 4.5:1 que o 1.4.3 pede, e reprovaria mesmo se fosse
texto grande. `#767676` é o cinza mais claro que passa sobre branco, com 4.54:1: um passo mais
claro, `#777777`, dá 4.48:1 e reprova. Ele não chega perto dos 7:1 do AAA, que é a troca que uma
designer faz de propósito ou não faz. O branco sobre vermelho-escuro do controle Book dá 10.20:1 e
o texto do corpo 15.91:1, os dois com folga acima de toda linha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-contrast\" aria-label=\"Uma escala de contraste de 1:1 a 21:1, num eixo logarítmico, com três limites: 3:1 para texto grande e partes de controles, 4.5:1 para texto no AA, 7:1 para texto no AAA. As cores da página de reserva estão nela: a nota cinza #999999 em 2.85, abaixo de todas as linhas; #777777 em 4.48, logo abaixo do AA; #767676 em 4.54, logo acima; a borda vermelha em 5.15; o branco no botão vermelho-escuro em 10.20; o texto do corpo em 15.91.\"><path d=\"M50.0 150.0 L680.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50.0 146.0 L50.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"50.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1:1</text><path d=\"M193.4 146.0 L193.4 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"193.4\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2:1</text><path d=\"M277.3 146.0 L277.3 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"277.3\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3:1</text><path d=\"M361.2 146.0 L361.2 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"361.2\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.5:1</text><path d=\"M452.7 146.0 L452.7 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"452.7\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7:1</text><path d=\"M526.5 146.0 L526.5 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"526.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:1</text><path d=\"M680.0 146.0 L680.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:1</text><path d=\"M277.3 40.0 L277.3 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"277.3\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AA grande · não texto</text><path d=\"M361.2 40.0 L361.2 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"361.2\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">AA texto</text><path d=\"M452.7 40.0 L452.7 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"452.7\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AAA texto</text><circle cx=\"266.7\" cy=\"150.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M266.7 144.0 L266.7 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"266.7\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#999</text><circle cx=\"360.3\" cy=\"150.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M360.3 144.0 L360.3 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"356.3\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#777</text><circle cx=\"363.1\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M363.1 144.0 L363.1 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"363.1\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#767676</text><circle cx=\"389.2\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M389.2 144.0 L389.2 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"389.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">borda vermelha</text><circle cx=\"530.6\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M530.6 144.0 L530.6 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"530.6\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">botão Book</text><circle cx=\"622.6\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M622.6 144.0 L622.6 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"622.6\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">texto</text><text x=\"360.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2.85 reprova em todo nível; um passo de cinza separa 4.48 de 4.54</text></svg>", "caption": "As cores da página de reserva na escala de contraste. Só a nota cinza fica abaixo das linhas que valem para ela."}
```

## Texto grande, e o que não é texto

**Texto grande** na WCAG tem pelo menos 18 pontos, ou 14 pontos em negrito, o que em CSS dá cerca
de 24 e 18.7 pixels. Ele fica com o limite mais baixo, 3:1, porque traços mais grossos continuam
legíveis com menos contraste. A nota do `book.html` tem 16 pixels e peso normal, então é texto
comum.

O *1.4.11 Contraste sem texto*, da WCAG 2.1, pede 3:1 do que não é texto: a borda de um campo, o
contorno do foco, um ícone que carrega significado. A borda vermelha do defeito 8 dá 5.15:1 contra
o branco e passa. **Vale reparar nisso, porque o defeito 8 continua sendo um defeito**: a borda é
fácil de ver, e continua sendo só uma cor. Contraste e uso de cor são dois critérios diferentes, e
passar num não diz nada do outro.

## Onde uma ferramenta ajuda e onde ela para

Medir contraste é a checagem mais automatizável da WCAG, e a ferramenta da aula 13 faz isso para
todo elemento da página. Ela descobre as cores que o navegador de fato desenhou, o que é mais
difícil do que parece: texto sobre um degradê ou uma fotografia não tem uma cor de fundo única, e
ali a ferramenta diz que não consegue decidir em vez de chutar. Para esses casos, e para cores num
arquivo de design que ainda não é página, um programa como este, ou o seletor de cores das
ferramentas de desenvolvedor do navegador, é como se acha o número.
