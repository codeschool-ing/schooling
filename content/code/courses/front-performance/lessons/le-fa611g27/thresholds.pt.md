---
title: Bom, precisa melhorar, ruim
version: 1
---

**Cada métrica tem dois limites, que dividem toda medida em bom, precisa melhorar e ruim.** Eles não
estão escritos num padrão; são do Google, e a biblioteca `web-vitals` os leva como constantes. Este
curso a instala na próxima seção; depois que ela estiver lá, os números podem ser lidos direto do
código que os aplica:

```
ana@dev:~/planner$ grep -h 'Thresholds = ' node_modules/web-vitals/dist/modules/on*.js
export const CLSThresholds = [0.1, 0.25];
export const FCPThresholds = [1800, 3000];
export const INPThresholds = [200, 500];
export const LCPThresholds = [2500, 4000];
export const TTFBThresholds = [800, 1800];
```

LCP e INP são em milissegundos e o CLS não tem unidade. A biblioteca também define limites para a
primeira pintura com conteúdo e para o tempo até o primeiro byte, que não são Core Web Vitals mas
ajudam a explicar um LCP.

## Uma página é julgada no 75º percentil

**Uma página passa quando três quartos das suas visitas são boas**, medido separadamente para cada
métrica e separadamente para celulares e computadores. O 75º percentil é um acordo escrito na
definição: a mediana deixaria metade dos visitantes passar mal, e o um por cento mais lento costuma
ser uma rede quebrada que nenhuma página conseguiria ajudar.

Então uma medida só, no seu próprio computador, não diz se uma página passa. Ela diz como foi uma
visita. **Os limites são para dados de campo**: valores mandados por muitos navegadores reais, que é
o que a seção "Dados de campo: o número do visitante" coleta. Uma medida aqui serve para achar uma
causa, mudá-la e medir de novo nas mesmas condições, que é o que as próximas três seções fazem.

## O que os números não dizem

**Uma nota boa não é uma página rápida; é uma página que não é lenta desses três jeitos.** Ela não diz
nada sobre quanto uma busca leva para responder, quão rápido a próxima página aparece depois de um
clique num link que faz uma navegação completa, ou se a página funciona numa rede que cai. Isso se
mede com as ferramentas da aula 6, contra metas que o time define para as suas próprias páginas.
