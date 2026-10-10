---
title: Robot Framework, QA Wolf, e como uma equipe escolhe
version: 1
---

Os dois últimos nomes da lista são os mais distantes do Playwright, e cada um responde a uma
pergunta diferente. **O Robot Framework muda quem consegue escrever um teste. O QA Wolf muda quem
o escreve, ponto.**

## Robot Framework

O Robot Framework se apresenta como "a generic open source automation framework for acceptance
testing, acceptance test driven development (ATDD), and robotic process automation (RPA)": um
framework genérico de automação para testes de aceitação e automação de processos. Ele é escrito em
Python, está na 7.5 no PyPI, e o desenvolvimento é patrocinado por uma fundação sem fins lucrativos.
Os testes dele não são código no sentido de costume: **um teste é uma lista de palavras-chave**,
cada uma uma frase curta seguida dos argumentos, separados por dois ou mais espaços. As
palavras-chave vêm de bibliotecas, e para navegador há duas: a **SeleniumLibrary** (6.9.0), que
funciona pelo Selenium e portanto pelo WebDriver, e a biblioteca **Browser** (20.6.0), que a
descrição dela diz ser "powered by Playwright", movida pelo Playwright.

O teste da banana com a SeleniumLibrary, num arquivo como `banana.robot`; o Robot Framework não foi
instalado neste curso, e isto não rodou:

```
*** Settings ***
Library    SeleniumLibrary

*** Test Cases ***
A banana goes into the basket
    Open Browser    http://localhost:3000/    headlesschrome
    Wait Until Element Is Visible    css:[data-testid=product-banana] button
    Click Button    css:[data-testid=product-banana] button
    Wait Until Element Contains    css:[data-testid=basket-count]    1
    [Teardown]    Close Browser
```

**O que importa é a camada de cima.** Uma equipe escreve palavras-chave próprias a partir dessas,
`Add Banana To Basket` ou `Basket Should Hold    1`, e os casos de teste viram frases que um
analista de negócio consegue ler e até escrever, que é a ideia de teste de aceitação da descrição.
O preço é uma segunda linguagem entre quem testa e o navegador. Quando uma palavra-chave se comporta
mal, alguém precisa ler o Python ou o Selenium por baixo, e as tabelas não escondem nada dessa
pessoa. **Uma equipe o escolhe** quando quem testa não programa, quando a empresa já usa Python, ou
quando a mesma ferramenta precisa conduzir outras coisas além de navegadores, o que as outras
bibliotecas do Robot fazem.

## QA Wolf, um serviço

O QA Wolf é uma empresa, e o que ela vende é **o trabalho, não uma ferramenta**. Do jeito que o
serviço costuma ser descrito, os engenheiros dela escrevem testes de ponta a ponta da sua aplicação
em código Playwright, rodam esses testes nas máquinas dela, mantêm os testes funcionando conforme a
aplicação muda e olham cada falha antes de avisar você. Este curso não o usou, e os termos, preços e
promessas são dela para declarar; leia-os no site dela, não aqui.

A empresa já publicou uma ferramenta. O pacote npm `qawolf` montava testes de navegador na sua
máquina, e o registro agora o marca como obsoleto, com uma mensagem que manda o leitor para o e-mail
da empresa. É o modelo numa linha: a ferramenta virou serviço.

O que uma equipe pesa é o mesmo de qualquer terceirização. Ela ganha uma suíte sem contratar para
isso. Ela abre mão de ter dentro de casa o conhecimento de *o que é testado e por quê*, que é o que
a aula 20 de `qa-fundamentals` diz decidir para onde vai o esforço de teste. Pergunte o que
acontece com os testes quando o contrato termina, e quem decide o que merece um teste, antes de
perguntar quantos testes vão ser.

## Como uma equipe escolhe

A lista de recursos é a última coisa que decide. Em ordem, as perguntas que em geral decidem:

1. **Que linguagem e que executor a equipe já usa?** Python aponta para o Robot Framework ou o
   Selenium para Python; uma suíte Jest aponta para uma biblioteca dentro do Jest; um front-end em
   TypeScript aponta para o Playwright ou o WebdriverIO.
2. **A que navegadores ela precisa chegar?** O CDP para no Chromium, então o Puppeteer não testa o
   Safari. O WebDriver chega a todo navegador que tem driver, e o Playwright chega ao WebKit pela
   versão própria dele.
3. **O que já roda os testes?** Uma grade de máquinas WebDriver ou os navegadores de um provedor na
   nuvem são um investimento, e o WebdriverIO, o Nightwatch e o Selenium os usam como estão.
4. **Quem escreve os testes?** Programadores, testadores que não programam, ou ninguém de dentro da
   empresa.

Uma equipe que responde a essas quatro em geral já escolheu antes de abrir a tabela de comparação,
e isso não é falha de julgamento: **uma ferramenta que a equipe já conhece, nos navegadores que
precisa cobrir, vence uma melhor que ninguém vai manter.** A aula 22 faz o mesmo tipo de pergunta
sobre quais testes valem a pena escrever.
