---
title: Lighthouse, WAVE e o painel do próprio navegador
version: 1
---

O axe num script é um jeito de rodar uma auditoria automática. Há outros três que um testador
encontra toda semana, e **cada um é uma janela diferente para quase as mesmas regras**: o
Lighthouse, que roda o axe e transforma o resultado numa nota; o WAVE, que desenha os achados na
própria página; e o painel de acessibilidade das ferramentas de desenvolvedor do navegador, que
mostra o que o navegador contou à tecnologia assistiva sobre cada elemento.

## A categoria de acessibilidade do Lighthouse

A aula 10 rodou o Lighthouse para desempenho. O mesmo comando, com outra categoria, roda as
auditorias de acessibilidade dele, que por baixo são regras do axe. A linha do `CHROME_PATH` que a
aula 10 acrescentou ao `~/.profile` continua valendo, e o `--no-sandbox` também, pelo motivo que a
aula 10 deu: um navegador de teste, abrindo só a sua própria página nesta máquina.

```
ana@nft:~/a11y$ lighthouse http://localhost:8000/book.html --only-categories=accessibility --output=json --output-path=book.json --chrome-flags="--headless=new --no-sandbox" --quiet
ana@nft:~/a11y$ jq -r ".categories.accessibility.score" book.json
0.55
ana@nft:~/a11y$ jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book.json
color-contrast: Background and foreground colors do not have a sufficient contrast ratio.
html-has-lang: `<html>` element does not have a `[lang]` attribute
image-alt: Image elements do not have `[alt]` attributes
label: Form elements do not have associated labels
landmark-one-main: Document does not have a main landmark.
tabindex: Some elements have a `[tabindex]` value greater than 0
```

**55 de 100**, e seis auditorias reprovadas. Quatro são as que o `audit.js` achou. As outras duas
são regras que o `audit.js` deixou de fora de propósito, porque têm a tag `best-practice` e não
WCAG: `landmark-one-main`, já que a página não tem `<main>`, e `tabindex`, que é o defeito 6. O
Lighthouse roda regras de boas práticas, então nesta página ele viu um defeito a mais que o script
só de WCAG. A mesma execução contra a página corrigida:

```
ana@nft:~/a11y$ lighthouse http://localhost:8000/book2.html --only-categories=accessibility --output=json --output-path=book2.json --chrome-flags="--headless=new --no-sandbox" --quiet
ana@nft:~/a11y$ jq -r ".categories.accessibility.score" book2.json
0.9
ana@nft:~/a11y$ jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book2.json
landmark-one-main: Document does not have a main landmark.
tabindex: Some elements have a `[tabindex]` value greater than 0
```

**90, com quatro correções.** A nota é uma média ponderada das auditorias que se aplicaram, e é uma
coisa útil de ver se mexer. É uma coisa ruim para pôr num requisito. Uma página com 90 pode ser
inutilizável para quem usa teclado, e o `book2.html` é: a `<div>` inalcançável não pesa nada na
nota, porque nenhuma auditoria a mediu.

O próprio relatório JSON diz isso. Ao lado das auditorias que rodou, ele lista as que não
conseguiu:

```
ana@nft:~/a11y$ jq -r ".audits[] | select(.scoreDisplayMode == \"manual\") | .title" book2.json
Custom controls have associated labels
Custom controls have ARIA roles
User focus is not accidentally trapped in a region
Interactive controls are keyboard focusable
Interactive elements indicate their purpose and state
The page has a logical tab order
The user's focus is directed to new content added to the page
Offscreen content is hidden from assistive technology
HTML5 landmark elements are used to improve navigation
Visual order on the page follows DOM order
```

**Essas dez são a lista do próprio Lighthouse do que uma pessoa tem que conferir**, e metade delas
é o que a aula 14 testa à mão: se os controles recebem o foco, se a ordem faz sentido, se o foco
fica preso em algum lugar. No relatório HTML elas ficam em *Additional items to manually check*,
recolhidas, abaixo de um número verde. Esse layout resume bem o quanto elas são lidas.

## WAVE

**O WAVE** é a ferramenta de avaliação da WebAIM: um site, `wave.webaim.org`, onde você digita um
endereço, e uma extensão para Chrome, Firefox e Edge que roda na página que está na sua frente.
Ele não foi rodado nesta aula, porque roda num navegador de desktop e o laboratório não tem
nenhum. Para testá-lo na página de reserva, suba a bilheteria com `BOXOFFICE_HOST=0.0.0.0` como a
aula 1 explica, abra o `book.html` pelo endereço da VM no seu próprio navegador e aperte o botão
da extensão. A versão do site não ajuda aqui: ela busca a página a partir dos servidores da
WebAIM, e eles não alcançam uma VM no seu computador.

O que diferencia o WAVE é onde ele põe a resposta. **Ele desenha um ícone na página, ao lado de
cada elemento sobre o qual tem algo a dizer**, e os lista num painel lateral em categorias:
erros, erros de contraste, alertas, recursos, elementos estruturais e ARIA. Os *erros* estão perto
das violações do axe. Os *alertas* são coisas de que o WAVE desconfia e não consegue confirmar,
como um link que só diz "clique aqui" ou um texto que parece título e não está marcado como tal;
são a mesma ideia do `incomplete` do axe. *Recursos* e *estrutura* são a surpresa útil: o WAVE
mostra também o que está certo, todo `alt`, todo rótulo, todo nível de título, para que o testador
veja o esqueleto da página como um leitor de tela anda por ele. A visão *No Styles* desliga o CSS
e mostra a ordem de leitura que a marcação de fato tem.

## As ferramentas de desenvolvedor

**As DevTools do Chrome têm um painel de acessibilidade** no painel Elements, ao lado de Styles.
Selecione um elemento e ele mostra o lugar desse elemento na árvore de acessibilidade, o papel
calculado, o nome acessível e de onde o nome veio, e os estados. É o jeito mais rápido de
responder "o que um leitor de tela vai dizer que isto é?" para um elemento, sem leitor de tela. O
Firefox tem o mesmo no Accessibility Inspector, com uma checagem de contraste e uma sobreposição
de ordem de tabulação que desenha números sobre cada elemento focável. As aulas 14 e 15 capturam a
mesma informação a partir de um script, e a aula 15 lê a árvore inteira.

O Lighthouse também tem um painel nas DevTools, que roda as mesmas auditorias da linha de comando
acima. Nenhum deles foi rodado aqui, pelo mesmo motivo do WAVE.
