---
title: Heurísticas: julgar o que ainda não foi visto
version: 1
---

**Uma heurística marca um arquivo pela aparência ou pelo que ele faz, e não por ser um arquivo
conhecido.** Assinaturas respondem "já vimos isto?". Heurísticas respondem "isto parece o tipo de
coisa que não queremos?", e por isso conseguem marcar um arquivo que ninguém nunca viu. O preço é a
incerteza: uma heurística dá uma probabilidade, não uma identidade, e erra mais vezes que uma
assinatura.

Nada nesta seção foi executado além das regras da anterior. Motores de heurística são o núcleo de
produtos comerciais e os fabricantes não os descrevem em detalhe suficiente para reproduzir; o que vem
a seguir é como funcionam em geral, a partir da documentação publicada do ClamAV e das explicações
dos próprios fabricantes.

## Três famílias

**Heurísticas estáticas** leem o arquivo sem rodá-lo e pontuam as propriedades dele.
Procuram um formato de
documento trazendo uma macro que roda quando ele é aberto, um executável cujas seções estão
comprimidas ou cifradas, um arquivo compactado protegido por senha para que nada dentro dele possa ser
lido, um arquivo cuja extensão diz um tipo e o conteúdo diz outro. Cada propriedade sozinha é comum em
arquivos legítimos. Uma combinação é suspeita. O ClamAV expõe algumas delas como opções, entre elas
`--alert-macros` para documentos com macros e `--alert-encrypted` para arquivos compactados e
documentos cifrados, que um gateway de e-mail muitas vezes liga.

**Emulação** roda uma pequena parte do programa dentro de um processador simulado, o bastante para ver
o que ele faz consigo mesmo: um programa que desempacota um segundo programa na memória mostra um
comportamento que um olhar estático não veria. É caro, então os scanners fazem isso rapidamente e só
para arquivos que já despertaram suspeita.

**Modelos de aprendizado de máquina**, treinados com milhões de arquivos sabidamente bons e ruins,
pontuam um arquivo novo pela semelhança com cada um. Generalizam bem para variantes e mal para
qualquer coisa de fato nova, que é justamente o que não estava no treino.

## Convivendo com os falsos positivos

A nota de treinamento da seção anterior é o que uma heurística produz todo dia, em maior quantidade.
As respostas são mais organizacionais que técnicas:

- **uma lista de permitidos** com arquivos que a organização decidiu que são bons, por hash, para as
  ferramentas internas que uma heurística sempre vai achar estranhas;
- **quarentena em vez de apagar**, para que um veredito errado custe um atraso, não um arquivo;
- **uma pessoa que revisa** o que foi para a quarentena, e um jeito de pedir o arquivo de volta;
- **ajuste por evidência**: uma regra que disparou em cem arquivos e acertou em nenhum é atenuada ou
  removida, e essa decisão é registrada como qualquer outra exceção da aula 2.

Uma heurística que nunca erra está tão cautelosa que não pega nada que uma assinatura não pegaria. Uma
heurística que inunda as pessoas de alertas logo é ignorada, e um alerta ignorado é pior que nenhum,
porque todo mundo acredita que alguma coisa está vigiando.
