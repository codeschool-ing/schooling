---
title: Tamanho da área de toque, medido contra o mínimo de cada plataforma
version: 1
---

**Uma área de toque é a região que responde ao dedo, e ela pode ser maior do que o que está
desenhado.** O tique do planner é um círculo de 24 por 24 na tela; nada impede que a área que
responde a ele tenha o dobro disso. O erro comum é tratar o desenho e a área como uma coisa só, e
então ou desenhar tudo enorme ou deixar ícones pequenos com áreas pequenas. As duas plataformas pedem
que o segundo número alcance um mínimo, e deixam o primeiro com o designer.

## Os números, e de onde vêm

| | área mínima | fonte, lida em 30 de outubro de 2026 |
|---|---|---|
| Android | **48 × 48 dp** | a documentação do Android: "uma área focável, ou tamanho de área de toque, de pelo menos 48dp x 48dp. Maior é ainda melhor." |
| iOS | **44 × 44 pt** | as HIG sobre botões: "um botão precisa de uma região de toque de pelo menos 44x44 pt" |
| a web, WCAG 2.2 | **24 × 24 pixels CSS** | o critério de sucesso 2.5.8, Target Size (Minimum), nível AA |

Três observações sobre a tabela. **Os dois números de celular estão na unidade de cada plataforma**,
`dp` e `pt`, que a aula 7 explicou, então 48 e 44 são tamanhos físicos da mesma ordem e não contagens
de pixels. **A página de acessibilidade das HIG dá dois números para o iOS**: 44 × 44 pt como tamanho
padrão de controle e 28 × 28 pt como mínimo, então 44 é a meta e 28 o menor tamanho que ela lista. E
**os 24 da WCAG são um piso para a web, com exceções**: uma área menor passa se um círculo de 24
pixels centrado nela não tocar outra área, ou se a mesma função estiver disponível em outro controle.
As plataformas de celular pedem números perto do dobro, e o planner segue os celulares.

## Conferindo o planner

O planner tem quatro tipos de controle na tela da semana, e cada um tem um tamanho desenhado em cada
plataforma. Um programa pequeno confere todos contra o mínimo da plataforma e diz, para cada um que
fica abaixo, quanta margem interna o leva até lá. Salve-o como `targets.ts` em `~/planner`:

```typescript
// targets.ts: the planner's touch targets against each platform's minimum
const MIN = { android: 48, ios: 44 }; // dp on Android, pt on iOS

type Target = { name: string; android: number[]; ios: number[] }; // [width, height]

const targets: Target[] = [
  { name: "add session", android: [56, 56], ios: [44, 44] },
  { name: "mark done", android: [24, 24], ios: [24, 24] },
  { name: "delete session", android: [40, 40], ios: [32, 32] },
  { name: "tab: Week", android: [96, 64], ios: [96, 49] },
];

// The padding that brings one side up to the minimum, split evenly around the control.
function padding(size: number, min: number): number {
  return Math.max(0, Math.ceil((min - size) / 2));
}

for (const t of targets) {
  for (const os of ["android", "ios"] as const) {
    const [w, h] = t[os];
    const unit = os === "android" ? "dp" : "pt";
    const pad = Math.max(padding(w, MIN[os]), padding(h, MIN[os]));
    const verdict = pad === 0 ? "ok" : `too small: add ${pad} ${unit} on each side`;
    console.log(`${t.name.padEnd(16)}${os.padEnd(8)}${`${w}x${h} ${unit}`.padEnd(11)}${verdict}`);
  }
}
```

```
ana@dev:~/planner$ node targets.ts
add session     android 56x56 dp   ok
add session     ios     44x44 pt   ok
mark done       android 24x24 dp   too small: add 12 dp on each side
mark done       ios     24x24 pt   too small: add 10 pt on each side
delete session  android 40x40 dp   too small: add 4 dp on each side
delete session  ios     32x32 pt   too small: add 6 pt on each side
tab: Week       android 96x64 dp   ok
tab: Week       ios     96x49 pt   ok
```

**Dois controles reprovam, nas duas plataformas, e são os dois que o aluno mais usa depois de
adicionar.** O tique tem 24 nas duas, então precisa de 12 dp de margem em cada lado no Android, o que
dá 48, e de 10 pt no iOS, o que dá 44. O botão de apagar precisa de 4 dp e 6 pt. O botão de ação
flutuante, com 56 dp, e a aba, com 96 por 64, passam com folga, e o botão da toolbar do iOS fica
exatamente em 44, o que passa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-padding\" aria-label=\"Dois quadrados, cada um uma área de toque com o tique desenhado no centro. À esquerda, Android: o tique tem 24 por 24 dp, a área 48 por 48 dp, com 12 dp de margem interna em cada lado. À direita, iOS: o tique tem 24 por 24 pt, a área 44 por 44 pt, com 10 pt de margem interna em cada lado. O desenho continua do mesmo tamanho; só cresce a área que responde ao dedo.\"><defs><marker id=\"l19-padding-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"190\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Android</text><rect x=\"118.0\" y=\"78.0\" width=\"144\" height=\"144\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"154\" y=\"114\" width=\"72\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 × 24</text><text x=\"190\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">área 48 × 48 dp</text><text x=\"190\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">tique desenhado</text><path d=\"M118.0 150 L154 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"112.0\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12 dp</text><path d=\"M190 78.0 L190 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"196\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12 dp</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS</text><rect x=\"464.0\" y=\"84.0\" width=\"132\" height=\"132\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"494\" y=\"114\" width=\"72\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 × 24</text><text x=\"530\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">área 44 × 44 pt</text><text x=\"530\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">tique desenhado</text><path d=\"M464.0 150 L494 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"458.0\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10 pt</text><path d=\"M530 84.0 L530 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-padding-ah-paper-dim)\" marker-start=\"url(#l19-padding-ah-paper-dim)\"></path><text x=\"536\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10 pt</text></svg>", "caption": "A correção que targets.ts pediu. O tique continua desenhado em 24; a margem em volta faz a área que o dedo acerta chegar ao mínimo de cada plataforma.", "same": ["Android", "iOS"]}
```

**A correção não mexe no desenho.** No Android, os componentes Material do Compose como `Button`,
`IconButton` e `ListItem` já impõem o mínimo de 48 dp, como a documentação do Android observa, e um
controle próprio o ganha com `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)` em volta de um
desenho menor. No SwiftUI o mesmo é um `.frame(minWidth: 44, minHeight: 44)` com
`.contentShape(Rectangle())`, para que o quadro inteiro responda ao toque e não só os pixels do
símbolo. Nenhum dos dois fragmentos foi executado para este curso; os números que eles alcançam são
os de cima.

**A margem tem um custo que o programa não vê.** Dois tiques de 24 lado a lado, cada um crescido para
48, agora se sobrepõem, e um dedo entre eles acerta o que o sistema escolher. O planner tem um tique
por linha e linhas mais altas do que 48, então as áreas dele nunca colidem; uma toolbar com cinco
botões de ícone em fila é onde isso pega, e é onde o conselho das HIG de pôr menos itens numa toolbar
também é uma regra de acessibilidade.
