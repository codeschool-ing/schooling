---
title: Escolhendo que quadros olhar
version: 1
---

Há três jeitos comuns de tirar quadros de um vídeo, e o programa da aula testa todos no vídeo de devolução da Marginalia e lê o título em cada quadro escolhido:

```python
"""Pull frames out of a video with one of five rules, and read the title on each."""
import os
import re
import shutil
import subprocess
import sys

RULES = {
    "every 5 s": ["-vf", "fps=1/5,showinfo"],
    "every 1 s": ["-vf", "fps=1,showinfo"],
    "scene > 0.3": ["-vf", r"select=gt(scene\,0.3),showinfo", "-vsync", "vfr"],
    "scene > 0.03": ["-vf", r"select=gt(scene\,0.03),showinfo", "-vsync", "vfr"],
    "keyframes": ["-skip_frame", "nokey", "-vf", "showinfo", "-vsync", "vfr"],
}


def title(png):
    """The first line Tesseract reads that has four letters or more and is not the shop's name."""
    out = subprocess.run(["tesseract", png, "-", "--psm", "6"], capture_output=True, text=True).stdout
    lines = [x for x in out.splitlines() if len(re.findall(r"\w", x)) >= 4 and x != "Marginalia"]
    return lines[0] if lines else "?"


def sample(video, rule, out):
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    args = RULES[rule][:2] if rule == "keyframes" else []
    rest = RULES[rule][2:] if rule == "keyframes" else RULES[rule]
    log = subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", *args, "-i", video, *rest, f"{out}/%03d.png"],
                         capture_output=True, text=True).stderr
    times = [float(t) for t in re.findall(r"pts_time:([0-9.]+)", log)]
    return [(t, os.path.join(out, f"{i:03}.png")) for i, t in enumerate(times, 1)]


if __name__ == "__main__":
    for rule in (sys.argv[2:] or RULES):
        frames = sample(sys.argv[1], rule, "/tmp/frames")
        titles = [title(p) for _, p in frames]
        print(f"{rule:13} {len(frames):3} frames  {len(set(titles)):2} different titles  "
              f"the 0.4 s card seen: {'yes' if any(t.startswith('Code:') for t in titles) else 'no'}")
```

```
ana@lab:~/mm$ python frames.py media/returns.mp4
every 5 s       7 frames   6 different titles  the 0.4 s card seen: no
every 1 s      33 frames   6 different titles  the 0.4 s card seen: no
scene > 0.3     2 frames   2 different titles  the 0.4 s card seen: yes
scene > 0.03    6 frames   6 different titles  the 0.4 s card seen: yes
keyframes       5 frames   5 different titles  the 0.4 s card seen: yes
```

O vídeo tem sete slides, e o arquivo de verdade diz exatamente quando cada um está na tela:

```
ana@lab:~/mm$ python -c "import json; [print(s[\"slide\"], s[\"start\"], s[\"end\"], s[\"title\"]) for s in json.load(open(\"media/truth/returns.json\"))[\"slides\"]]"
1 0.0 5.92 Returning a book to Marginalia
2 5.92 11.64 1. Open the order
3 11.64 15.68 2. Choose a reason
4 15.68 20.72 3. Print the label
5 20.72 21.12 Code: RETURN30
6 21.12 26.44 4. Drop it off
7 26.44 32.6 Refunds
```

**Uma taxa fixa** pega um quadro de tanto em tanto tempo. Um a cada 5 segundos deu 7 quadros e viu 6 dos 7 títulos; um por segundo deu 33 quadros e viu os mesmos 6. Os dois perderam o slide 5, o cartão que fica na tela de 20,72 a 21,12 segundos. Para a taxa de 5 segundos o motivo é simples: as batidas em 20 e 25 caem dos dois lados de uma janela de 0,4 segundo. A taxa de 1 segundo tem uma batida em 21,0, dentro do cartão, e mesmo assim o perdeu. O motivo é o jeito como o filtro `fps` do ffmpeg escolhe um quadro para cada batida: todo quadro de entrada de 20,5 a 21,5 segundos é arredondado para a batida de 21, e o filtro fica com o último deles, um quadro do slide seguinte. Pedir exatamente aquele instante mostra o que havia lá:

```
ana@lab:~/mm$ ffmpeg -nostdin -loglevel error -y -ss 21 -i media/returns.mp4 -frames:v 1 /tmp/at21.png && tesseract /tmp/at21.png - --psm 6 2>/dev/null | head -2
Code: RETURN3O
Quote it if you call us
```

Então uma taxa fixa só é tão boa quanto a regra que escolhe o quadro de cada batida, e essa regra é da ferramenta, não sua. Passar de um quadro a cada 5 segundos para um por segundo custou quase cinco vezes mais quadros e, aqui, não achou nada novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os 32,6 segundos de returns.mp4 desenhados em duas faixas. A faixa de cima, o que é mostrado, são sete slides; o quinto dura só 0,4 segundo, de 20,72 a 21,12, e está marcado. A faixa de baixo, o que é dito, são seis trechos de fala, com silêncio sobre o cartão curto. Abaixo delas, duas fileiras de marcas: uma a cada 5 segundos, com marcas em 20 e 25 dos dois lados do cartão, e uma a cada segundo, cuja marca em 21 cai dentro dele.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mostrado</text><rect x=\"110.0\" y=\"26\" width=\"105.32515337423314\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"162.66257668711657\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"215.32515337423314\" y=\"26\" width=\"101.7668711656442\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"266.2085889570552\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"317.09202453987734\" y=\"26\" width=\"71.87730061349686\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"353.03067484662574\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"388.9693251533742\" y=\"26\" width=\"89.6687116564417\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.80368098159505\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"478.6380368098159\" y=\"26\" width=\"7.116564417177983\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"485.7546012269939\" y=\"26\" width=\"94.65030674846622\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"533.079754601227\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"580.4049079754601\" y=\"26\" width=\"109.5950920245399\" height=\"28\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.20245398773\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"482.1963190184049\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cartão de 0,4 s</text><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dito</text><rect x=\"117.47239263803681\" y=\"92\" width=\"84.86503067484665\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"222.79754601226995\" y=\"92\" width=\"80.95092024539878\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"324.2085889570552\" y=\"92\" width=\"52.30674846625766\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"396.441717791411\" y=\"92\" width=\"69.56441717791415\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"498.3865030674846\" y=\"92\" width=\"68.85276073619633\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"588.4110429447853\" y=\"92\" width=\"89.31288343558276\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a cada 5 s</text><line x1=\"110.0\" y1=\"142\" x2=\"110.0\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"198.95705521472394\" y1=\"142\" x2=\"198.95705521472394\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"287.9141104294479\" y1=\"142\" x2=\"287.9141104294479\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"376.87116564417175\" y1=\"142\" x2=\"376.87116564417175\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"465.8282208588957\" y1=\"142\" x2=\"465.8282208588957\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"554.7852760736196\" y1=\"142\" x2=\"554.7852760736196\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"643.7423312883435\" y1=\"142\" x2=\"643.7423312883435\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"20\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a cada 1 s</text><line x1=\"110.0\" y1=\"174\" x2=\"110.0\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"127.79141104294479\" y1=\"174\" x2=\"127.79141104294479\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"145.58282208588957\" y1=\"174\" x2=\"145.58282208588957\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"163.37423312883436\" y1=\"174\" x2=\"163.37423312883436\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"181.16564417177915\" y1=\"174\" x2=\"181.16564417177915\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"198.95705521472394\" y1=\"174\" x2=\"198.95705521472394\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"216.74846625766872\" y1=\"174\" x2=\"216.74846625766872\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"234.5398773006135\" y1=\"174\" x2=\"234.5398773006135\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"252.33128834355827\" y1=\"174\" x2=\"252.33128834355827\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"270.1226993865031\" y1=\"174\" x2=\"270.1226993865031\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"287.9141104294479\" y1=\"174\" x2=\"287.9141104294479\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"305.70552147239266\" y1=\"174\" x2=\"305.70552147239266\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"323.49693251533745\" y1=\"174\" x2=\"323.49693251533745\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"341.28834355828224\" y1=\"174\" x2=\"341.28834355828224\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"359.079754601227\" y1=\"174\" x2=\"359.079754601227\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"376.87116564417175\" y1=\"174\" x2=\"376.87116564417175\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"394.66257668711654\" y1=\"174\" x2=\"394.66257668711654\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"412.4539877300613\" y1=\"174\" x2=\"412.4539877300613\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"430.2453987730061\" y1=\"174\" x2=\"430.2453987730061\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"448.0368098159509\" y1=\"174\" x2=\"448.0368098159509\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"465.8282208588957\" y1=\"174\" x2=\"465.8282208588957\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"483.6196319018405\" y1=\"174\" x2=\"483.6196319018405\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"501.41104294478527\" y1=\"174\" x2=\"501.41104294478527\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"519.20245398773\" y1=\"174\" x2=\"519.20245398773\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"536.9938650306749\" y1=\"174\" x2=\"536.9938650306749\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"554.7852760736196\" y1=\"174\" x2=\"554.7852760736196\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"572.5766871165645\" y1=\"174\" x2=\"572.5766871165645\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"590.3680981595091\" y1=\"174\" x2=\"590.3680981595091\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"608.159509202454\" y1=\"174\" x2=\"608.159509202454\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"625.9509202453987\" y1=\"174\" x2=\"625.9509202453987\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"643.7423312883435\" y1=\"174\" x2=\"643.7423312883435\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"661.5337423312883\" y1=\"174\" x2=\"661.5337423312883\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"679.3251533742331\" y1=\"174\" x2=\"679.3251533742331\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"478.6380368098159\" y1=\"20\" x2=\"478.6380368098159\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"485.7546012269939\" y1=\"20\" x2=\"485.7546012269939\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"110.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"287.9141104294479\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><text x=\"465.8282208588957\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><text x=\"643.7423312883435\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text></svg>", "caption": "As marcas de 5 segundos perdem o cartão; a de 1 segundo cai nele, e o quadro que o ffmpeg entregou para essa marca era de depois."}
```

**A detecção de cena** pega um quadro onde a imagem muda. A nota `scene` do ffmpeg compara cada quadro com o anterior, de 0 para idênticos a 1 para completamente diferentes. Com limite de 0,3 ela achou só 2 quadros: o corte para o cartão escuro e o corte de saída dele, os dois com nota 1,0. Passar de um slide claro para o próximo slide claro dá bem menos, entre 0,04 e 0,06 neste vídeo, e um limite de 0,03 pegou todos os cortes: 6 quadros, 6 títulos, o cartão incluído. O único título que ele não viu é o do primeiro slide, porque nenhum corte leva ao primeiro quadro de um vídeo; a linha do tempo, mais adiante, acrescenta esse quadro à mão.

**Os quadros-chave** são os que o codificador escolheu guardar inteiros, e ele põe um onde a imagem muda muito. Aqui isso deu 5 quadros, incluindo o cartão, e perdeu dois slides cuja mudança foi pequena demais para o codificador se dar ao trabalho.

## Qual usar

| regra | boa para | fraca em |
|---|---|---|
| uma taxa fixa | vídeo em que as coisas mudam o tempo todo: uma rua, um esporte, uma gravação de tela com movimento | eventos breves entre as batidas; o custo cresce com a duração |
| detecção de cena | slides, cortes entre tomadas, tudo o que é feito de cenas distintas | uma mudança gradual; o limite precisa ser ajustado para cada tipo de vídeo |
| quadros-chave | uma primeira passada rápida e de graça: o codificador já fez o trabalho | ele decidiu pela compressão, não pelo sentido |

O limite de 0,03 está certo para este vídeo e errado para a maioria dos outros; uma cena de rua muda isso tudo entre cada par de quadros. **Meça nos seus próprios vídeos**, contra alguns em que você sabe o que acontece, como este laboratório mediu contra o arquivo de verdade.
