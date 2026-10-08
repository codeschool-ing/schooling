---
title: Eixos, unidades e as palavras em volta
version: 1
---

O título de um eixo responde "que número é este?", e um número sem unidade não responde nada.
**Pedidos, minutos, reais, por cento, por mil habitantes**: a unidade vai no gráfico, toda vez, porque
o leitor não tem outro jeito de saber.

## O que todo eixo precisa

- **O que é medido, e em que unidade**: "tempo de entrega (minutos)", "receita (R$ mil)". Se a unidade
  estiver em escala, diga: mil, milhões.
- **Marcas suficientes para ler valores, e não mais.** Quatro a seis marcas na maioria dos eixos.
  Números redondos: 0, 20, 40, 60, e não 0, 17, 34, 51.
- **Um eixo de tempo rotulado como as pessoas escrevem datas.** "jan 2024, jul, jan 2025", e não
  "2024-01-01T00:00:00".

## O que pode sair

Texto que repete o que o leitor já sabe é ruído. A aula 17 é sobre tirar ruído; três casos valem ser
citados aqui.

- **Um título de eixo que o título já diz.** Se o título diz "pedidos mensais", o eixo vertical pode
  dizer "pedidos" ou nada.
- **Um título de eixo de categoria** como "Região" acima de uma lista de regiões. Os nomes se explicam
  sozinhos.
- **Linha de eixo e linhas de grade com força total.** Mantenha a linha de base; deixe as linhas de
  grade discretas ou tire-as.

## Gire o gráfico, não o texto

A aula 3 disse isso das barras e vale para tudo: **o texto deve ficar na horizontal**. Um título de
eixo vertical girado 90 graus é lido inclinando a cabeça. Ponha o título do eixo acima do eixo, na
horizontal, no canto de cima à esquerda, onde o olho começa de qualquer jeito. Toda figura deste curso
faz isso, e o matplotlib precisa de duas linhas para fazer isso no lugar do padrão girado.

## O subtítulo e a fonte

Embaixo de um título que afirma, um **subtítulo** mais discreto carrega o rótulo: o quê, onde, quando,
unidade. No pé, uma **linha de fonte** diz de onde veio o dado: "Fonte: pedidos da Horta, janeiro de
2024 a dezembro de 2025". Nenhum dos dois é decoração. Um gráfico sem fonte não pode ser conferido, e
um gráfico que não pode ser conferido pede para ser acreditado.
