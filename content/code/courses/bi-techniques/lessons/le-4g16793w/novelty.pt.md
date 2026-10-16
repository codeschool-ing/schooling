---
title: O efeito de novidade
version: 1
---

As pessoas reagem a algo porque é novo: clicam no botão desconhecido para ver o que ele faz, ou leem
a página redesenhada com mais atenção que a antiga. **O efeito de novidade é uma alta que se apaga
conforme os visitantes se acostumam com a mudança.** O espelho dele é a **aversão à mudança**, em que
visitantes que voltam se saem pior com um desenho novo por um tempo, até aprenderem. De um jeito ou
de outro, os primeiros dias de um teste descrevem a reação à mudança, e os seguintes descrevem a
mudança.

```schooling-example
{"language": "python", "file": "novelty.py", "parts": [{"code": "import pandas as pd\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])\nvisits[\"week\"] = (visits[\"day\"] - visits[\"day\"].min()).dt.days // 7 + 1", "note": "Numera o dia de cada visitante como semana 1, 2 ou 3 do teste."}, {"code": "rates = visits.pivot_table(index=\"week\", columns=\"group\", values=\"converted\", aggfunc=\"mean\")\nrates[\"lift, points\"] = (rates[\"new\"] - rates[\"old\"]) * 100\nprint((rates[[\"old\", \"new\"]] * 100).round(2).join(rates[\"lift, points\"].round(2)).to_string())", "note": "A conversão em por cento de cada grupo em cada semana, e a diferença entre eles em pontos percentuais."}], "output": "       old   new  lift, points\nweek                          \n1     4.31  5.35          1.04\n2     4.35  4.25         -0.10\n3     4.17  4.42          0.25"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l09-daily\" aria-label=\"Conversão diária do checkout antigo e do novo nos 21 dias do teste. Nos primeiros quatro dias a linha nova fica bem acima da antiga, cerca de 5,4 a 6,8 por cento contra 3,2 a 4,5. Da segunda semana em diante as duas linhas se cruzam e recruzam em torno de 4 a 5 por cento.\"><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 220.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M60.0 160.0 L600.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 160.0 L60.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M60.0 100.0 L600.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 100.0 L60.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M60.0 40.0 L600.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 40.0 L60.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"60.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">conversão, por cento</text><path d=\"M60.0 220.0 L600.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semana 1</text><text x=\"330.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semana 2</text><path d=\"M240.0 40.0 L240.0 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"510.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">semana 3</text><path d=\"M420.0 40.0 L420.0 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M72.9 145.6 L98.6 184.4 L124.3 176.3 L150.0 144.3 L175.7 145.5 L201.4 118.4 L227.1 139.7 L252.9 155.2 L278.6 140.1 L304.3 156.4 L330.0 153.5 L355.7 167.1 L381.4 153.4 L407.1 122.1 L432.9 134.4 L458.6 176.5 L484.3 161.2 L510.0 134.3 L535.7 135.7 L561.4 153.5 L587.1 188.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M72.9 96.7 L98.6 76.2 L124.3 116.9 L150.0 107.2 L175.7 134.8 L201.4 154.3 L227.1 150.4 L252.9 114.7 L278.6 176.8 L304.3 131.4 L330.0 154.0 L355.7 185.8 L381.4 158.9 L407.1 146.1 L432.9 195.4 L458.6 186.2 L484.3 158.8 L510.0 125.8 L535.7 117.0 L561.4 104.5 L587.1 145.3\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M80.0 262.0 L104.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"110.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout antigo</text><path d=\"M280.0 262.0 L304.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"310.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout novo</text></svg>", "caption": "A vantagem da página nova se concentra nos primeiros dias. Uma média das três semanas mistura uma reação à novidade com o efeito duradouro."}
```

**Na primeira semana o checkout novo converteu 5,35 por cento dos visitantes contra 4,31, uma alta de
1,04 ponto. Na segunda semana a alta foi −0,10, e na terceira 0,25.** O efeito total do teste, que a
aula 10 calcula sobre as três semanas, é a média de uma primeira semana grande e um resto pequeno.
Lançada com base na média, a mudança entregaria bem menos do que a média prometeu, porque todo
visitante depois do lançamento já passou da primeira semana.

## O que fazer

- **Olhe o efeito ao longo do tempo** como rotina, por semana ou por dia, antes de relatar o total.
  Uma alta concentrada no começo é um alerta; uma alta que se mantém tranquiliza.
- **Separe visitantes novos dos que voltam** onde o teste tem os dois. A novidade atinge quem volta,
  que conhecia o desenho antigo; quem vê o site pela primeira vez não tem com o que se surpreender.
- **Rode tempo bastante para o efeito se assentar**, no que a regra das semanas inteiras da aula 8 já
  ajuda. Quando a decisão importa e as primeiras semanas parecem diferentes, a estimativa honesta é a
  das semanas seguintes, e ela vem com menos visitantes e um intervalo mais largo.

O teste da Panela foi montado com um efeito de novidade dentro: o `panela.py` dá à página nova uma
alta extra que decai dia a dia, em cima de 0,4 ponto constantes. As altas semanais acima são o
formato disso através de três semanas de ruído, e a aula 10 pergunta o que isso faz com a decisão.
