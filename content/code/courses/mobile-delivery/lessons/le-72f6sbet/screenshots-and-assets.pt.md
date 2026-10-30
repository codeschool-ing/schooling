---
title: Capturas de tela, o ícone e os tamanhos que são recusados
version: 1
---

**As imagens vendem o app, e cada loja recusa o tamanho errado no envio, antes que alguém as tenha
olhado.** As pessoas decidem pelas duas ou três primeiras capturas, muitas vezes sem rolar a
página, então essas são as que mais merecem atenção.

## Apple

O App Store Connect pede entre **uma e dez capturas por tamanho de aparelho**, em JPEG ou PNG. Para
o iPhone, o tamanho exigido maior é o que importa: a Apple o reduz para iPhones menores quando a
interface é a mesma em todos. Os tamanhos aceitos em retrato para a tela grande do iPhone incluem
**1320 × 2868** e **1290 × 2796** pixels; uma imagem de qualquer outro tamanho é recusada quando
você a solta na página. Um build para iPad precisa de capturas de iPad também.

Os **app previews** são vídeos curtos nos mesmos espaços, tocados sem som por padrão. O **ícone**
vem do próprio app, do catálogo de assets do build, e não da ficha.

## Google

O Google Play pede pelo menos duas capturas de celular e aceita até oito, em JPEG ou PNG de 24 bits
sem transparência. Cada lado precisa ter entre **320 e 3840 pixels**, e o lado maior no máximo o
**dobro** do menor. Além disso, a ficha leva dois artes próprios: um **ícone de 512 × 512**, enviado
à parte do que está dentro do app, e um **gráfico de destaque de 1024 × 500**, o banner mostrado no
topo da página e em promoções. *Os números do Google são da ajuda de 2025 dele; a máquina de
gravação não conseguiu abri-la.*

## O que uma captura deveria mostrar

- **O app fazendo o trabalho dele, e não a tela de abertura.** A primeira imagem do planner é a
  semana com sessões e um total, porque é isso que a pessoa quer.
- **Uma ideia por imagem, com uma legenda que a diz.** A maioria das fichas põe uma linha curta de
  texto acima do celular; a pessoa lê isso, e não a interface.
- **Dados com cara de reais, inventados de propósito.** Capturas são públicas: o nome de um colega,
  um e-mail real ou os dados de um cliente numa delas é um problema de privacidade, e a lição 5
  trata do formulário que pergunta sobre isso.
- **As mesmas imagens em todo idioma, com as legendas traduzidas.** Uma página em português com
  legendas em inglês diz ao visitante que o app não foi feito para ele.

## Geradas, e não feitas à mão

Tirar vinte capturas à mão para cada idioma e cada release é como fichas ficam desatualizadas. Cada
plataforma consegue produzi-las a partir de testes: testes de UI do Xcode conduzidos pelo **fastlane
snapshot** no iOS, **fastlane screengrab** ou testes de captura do Compose no Android, e fluxos do
Maestro para React Native. A lição 11 roda o Fastlane. O que a loja recebe passa a ser uma pasta de
arquivos, que é o assunto da seção "A ficha como arquivos".
