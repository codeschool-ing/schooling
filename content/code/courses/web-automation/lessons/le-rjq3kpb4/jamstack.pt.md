---
title: JAMstack, onde o build é o que você testa
version: 1
---

**JAMstack** é o nome de um jeito de entregar um site: JavaScript, APIs e Markup. As páginas são
geradas **com antecedência** como arquivos HTML simples por um gerador, esses arquivos são servidos
por uma rede de distribuição de conteúdo, uma **CDN**, e o que precisa mudar por visitante, uma cesta
ou uma busca, vem de uma API buscada por JavaScript no navegador. O nome se ouve menos do que já se
ouviu; o formato está em toda parte, em sites de documentação, vitrines de loja e páginas de
marketing. De onde uma página tira o seu HTML, do navegador ou do servidor, é a aula 6. Esta seção
trata do que a entrega muda para um teste.

A crença a abandonar é a de que o site que você testa enquanto desenvolve é o site que vai ao ar.
Neste formato não é, e três coisas decorrem disso.

## A saída do build é o que se testa

O que chega aos usuários é a pasta que o build escreveu, servida como arquivos. Durante o
desenvolvimento, as mesmas páginas vêm de um servidor de desenvolvimento, que refaz o build a cada
gravação e muitas vezes é mais gentil que a produção. **Os links diretos de uma SPA são o caso
clássico**: o servidor de desenvolvimento do Vite, diz a documentação dele, responde endereços
desconhecidos com a página do app por padrão, então uma suíte rodada contra ele nunca encontra o 404
de duas seções atrás. A suíte que vale roda contra a pasta gerada, servida por um servidor estático
que não sabe nada que o host de produção não saiba. O `app/public/` da quitanda é a mesma ideia no
seu tamanho mínimo: arquivos, servidos como são.

## Deploys de pré-visualização

Hosts estáticos costumam gerar cada pull request e publicá-lo num endereço próprio, um **deploy de
pré-visualização**. Isso dá a uma suíte um lugar real para rodar antes de qualquer merge, no mesmo
tipo de host que a produção. Também muda a configuração: o endereço é diferente a cada pull request,
então ele vem de uma variável de ambiente e não de um `webServer` que a própria suíte inicia. A aula
10 trata da configuração do Playwright, e de como uma suíte roda contra vários endereços.

## Uma CDN na frente

Uma CDN guarda cópias em muitas bordas, perto dos usuários, e um deploy chega a elas aos poucos, não
de uma vez. É o cache da aula 4 uma camada mais longe, com a mesma consequência: um teste rodado
contra a produção logo depois de um deploy pode encontrar a versão anterior. Um teste que precisa
saber com que versão está falando precisa que a versão diga isso, num cabeçalho ou na página, em vez
de um palpite baseado no horário.

Há uma segunda consequência, sobre dados. **O que foi embutido na hora do build tem a idade do
build.** Um preço que a API mudou hoje de manhã ainda é o preço de ontem numa página gerada ontem,
até o próximo build. Um teste que confere um preço contra a API pode estar certo sobre os dois e
falhar mesmo assim; a aula 20 de `manual-testing` trata de escolher dados de teste que não se mexem
debaixo de um teste.

Nada disso rodou para o curso: não há host estático nem CDN por trás destas aulas, então a seção não
mostra transcrições, só as perguntas a fazer ao que você encontrar.
