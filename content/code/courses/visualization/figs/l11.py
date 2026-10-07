# Lesson 11 — hue, saturation and lightness. The colours here are the subject, so they are
# literal values, and no text is drawn on them.
import colorsys


def to_hex(r, g, b):
    def c(v):
        return max(0, min(255, round(v * 255)))
    return f'#{c(r):02x}{c(g):02x}{c(b):02x}'


def hsl(h, s, l):
    return to_hex(*colorsys.hls_to_rgb(h / 360, l, s))


def lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def unlin(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def luminance(hex_colour):
    r, g, b = (lin(int(hex_colour[i:i + 2], 16) / 255) for i in (1, 3, 5))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def oklch(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return to_hex(unlin(r), unlin(g), unlin(bb))


def grey(y):
    """The grey with the same relative luminance as y."""
    v = unlin(y)
    return to_hex(v, v, v)


@figure('l11-three', 11)
def l11_three(lang):
    w = {'en': dict(
        label='Three rows of colour swatches. The first changes hue all the way round, red, '
              'orange, yellow, green, cyan, blue, purple, magenta and back to red, at full '
              'saturation. The second keeps one blue hue and changes saturation, from grey to '
              'vivid blue. The third keeps the same blue and changes lightness, from black to '
              'white.',
        h='hue', s='saturation', l='lightness',
        cap='Three questions about any colour: which colour family (hue), how much colour '
            'against grey (saturation), how light or dark (lightness).'),
        'pt': dict(
        label='Três fileiras de amostras de cor. A primeira muda o matiz por toda a volta, '
              'vermelho, laranja, amarelo, verde, ciano, azul, roxo, magenta e de volta ao '
              'vermelho, em saturação máxima. A segunda mantém um matiz azul e muda a saturação, '
              'do cinza ao azul vivo. A terceira mantém o mesmo azul e muda a luminosidade, do '
              'preto ao branco.',
        h='matiz', s='saturação', l='luminosidade',
        cap='Três perguntas sobre qualquer cor: que família de cor (matiz), quanta cor contra o '
            'cinza (saturação), quão clara ou escura (luminosidade).')}[lang]
    f = Fig('l11-three', 620, 210, w['label'])
    n = 12
    for k in range(n):
        x = 130 + k * 38
        f.rect(x, 20, 34, 44, stroke='--wire', fill=hsl(k * 360 / n, 1, 0.5), rx=2, width=1)
        f.rect(x, 82, 34, 44, stroke='--wire', fill=hsl(220, k / (n - 1), 0.5), rx=2, width=1)
        f.rect(x, 144, 34, 44, stroke='--wire', fill=hsl(220, 0.75, 0.04 + 0.92 * k / (n - 1)),
               rx=2, width=1)
    for y, t in ((42, w['h']), (104, w['s']), (166, w['l'])):
        f.text(118, y, t, size=11, anchor='end', weight='600')
    return f, w['cap']


@figure('l11-same-l', 11)
def l11_same_l(lang):
    hues = [0, 60, 120, 180, 240, 300]
    w = {'en': dict(
        label='Six fully saturated colours that HSL says are all at 50% lightness: red, yellow, '
              'green, cyan, blue and magenta. Below each, the grey with the same brightness to the '
              'eye, and a bar of its relative luminance. Yellow\'s grey is nearly white and its bar '
              'reaches 0.93; blue\'s grey is nearly black and its bar is 0.07.',
        top='HSL lightness: 50% each', mid='the grey the eye sees',
        bot='relative luminance',
        cap='HSL calls all six "50% lightness". The eye does not agree: yellow is thirteen times '
            'as bright as blue. A palette built on HSL lightness is uneven before it starts.'),
        'pt': dict(
        label='Seis cores de saturação máxima que o HSL diz estarem todas em 50% de luminosidade: '
              'vermelho, amarelo, verde, ciano, azul e magenta. Embaixo de cada uma, o cinza com o '
              'mesmo brilho para o olho, e uma barra da sua luminância relativa. O cinza do amarelo '
              'é quase branco e a barra dele chega a 0,93; o cinza do azul é quase preto e a barra '
              'dele é 0,07.',
        top='luminosidade HSL: 50% cada', mid='o cinza que o olho vê',
        bot='luminância relativa',
        cap='O HSL chama as seis de "50% de luminosidade". O olho discorda: o amarelo é treze vezes '
            'mais brilhante que o azul. Uma paleta construída na luminosidade do HSL já nasce '
            'desigual.')}[lang]
    f = Fig('l11-same-l', 600, 300, w['label'])
    for k, h in enumerate(hues):
        x = 170 + k * 68
        c = hsl(h, 1, 0.5)
        y = luminance(c)
        f.rect(x, 20, 52, 52, stroke='--wire', fill=c, rx=2, width=1)
        f.rect(x, 90, 52, 52, stroke='--wire', fill=grey(y), rx=2, width=1)
        f.bar(x + 6, 270 - 100 * y, 40, 100 * y, stroke='--phosphor', fill='--phosphor-dim')
        f.text(x + 26, 270 - 100 * y - 10, num(lang, y, 2), size=9.5, mono=True)
    f.line(160, 270, 580, 270, stroke='--paper-dim', width=1.2)
    f.text(156, 46, w['top'], size=10, anchor='end')
    f.text(156, 116, w['mid'], size=10, anchor='end')
    f.text(156, 230, w['bot'], size=10, anchor='end')
    return f, w['cap']


@figure('l11-ramps', 11)
def l11_ramps(lang):
    steps = 7
    hsl_ramp = [hsl(60, 0.8, 0.92 - 0.8 * k / (steps - 1)) for k in range(steps)]
    ok_ramp = [oklch(0.97 - 0.62 * k / (steps - 1), 0.05 + 0.07 * k / (steps - 1), 100)
               for k in range(steps)]
    w = {'en': dict(
        label='Two seven-step yellow ramps from pale to dark, with the perceived lightness of each '
              'step plotted beneath as a line. The first ramp takes equal steps of HSL lightness, '
              'and its line bends: the first four steps are almost the same pale yellow and the '
              'last three drop steeply. The second takes equal steps in OKLCH, a space built to '
              'match perception, and its line falls straight.',
        a='equal steps in HSL', b='equal steps in OKLCH', y='perceived lightness (OKLab L)',
        cap='Equal steps in a perceptual space look equal; equal steps in HSL do not. A sequential '
            'palette is only honest if a step of one class is the same visual step everywhere.'),
        'pt': dict(
        label='Duas rampas de amarelo de sete passos do claro ao escuro, com a luminosidade percebida '
              'de cada passo desenhada embaixo como uma linha. A primeira rampa dá passos iguais de '
              'luminosidade HSL, e a linha dela se curva: os quatro primeiros passos são quase o '
              'mesmo amarelo claro e os três últimos caem forte. A segunda dá passos iguais em '
              'OKLCH, um espaço feito para combinar com a percepção, e a linha dela cai reta.',
        a='passos iguais em HSL', b='passos iguais em OKLCH', y='luminosidade percebida (L do OKLab)',
        cap='Passos iguais num espaço perceptual parecem iguais; passos iguais em HSL não. Uma '
            'paleta sequencial só é honesta se um passo de classe for o mesmo passo visual em '
            'todo lugar.')}[lang]

    def ok_l(hx):
        r, g, b = (lin(int(hx[i:i + 2], 16) / 255) for i in (1, 3, 5))
        l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
        m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
        s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
        return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s

    f = Fig('l11-ramps', 620, 290, w['label'])
    for k, (ramp, title) in enumerate(((hsl_ramp, w['a']), (ok_ramp, w['b']))):
        x0 = 40 + k * 300
        f.text(x0, 20, title, size=10.5, anchor='start', weight='600')
        for i, c in enumerate(ramp):
            f.rect(x0 + i * 36, 34, 32, 40, stroke='--wire', fill=c, rx=2, width=1)
        p = Plot(f, x0, 110, x0 + 6 * 36 + 32, 250, -0.5, 6.5, 0.2, 1.0)
        f.line(p.x0, p.y1, p.x1, p.y1, stroke='--paper-dim', width=1)
        f.line(p.x0, p.y0, p.x0, p.y1, stroke='--paper-dim', width=1)
        pts = [(p.sx(i), p.sy(ok_l(c))) for i, c in enumerate(ramp)]
        f.poly(pts, stroke='--amber', width=2)
        for x, y in pts:
            f.circle(x, y, 3.5, fill='--amber')
    f.text(40, 272, w['y'], size=9.5, anchor='start', fill='--paper-dim')
    return f, w['cap']


@image('l11-grid.svg', 11)
def l11_grid_image():
    f = Fig('l11-grid-image', 600, 320,
            'A grid of colour swatches with no words: one column of greys on the left, then twelve '
            'columns of hues going round the colour circle from red, and six rows from light at the '
            'top to dark at the bottom.')
    levels = [0.85, 0.7, 0.55, 0.4, 0.25, 0.1]
    for r, l in enumerate(levels):
        y = 20 + r * 46
        f.rect(60, y, 34, 42, stroke='--wire', fill=hsl(0, 0, l), rx=2, width=1)
        for k in range(12):
            f.rect(120 + k * 38, y, 34, 42, stroke='--wire', fill=hsl(k * 30, 1, l), rx=2, width=1)
    return f
