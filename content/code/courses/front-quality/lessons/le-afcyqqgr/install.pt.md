---
title: O Playwright, e um navegador só dele
version: 1
---

**O Playwright é uma biblioteca que controla um navegador de verdade a partir de um programa, e o
Playwright Test é o executor construído em volta dela.** As aulas 2 e 3 rodaram o planner num
documento simulado no Node; daqui em diante o planner roda no Chromium, o navegador a partir do qual o
Chrome é feito, com layout, CSS, rede e relógio. O executor é um pacote só, na versão que este curso
fixa, a 1.63.0:

```
ana@dev:~/planner$ npm install --save-exact -D @playwright/test@1.63.0

added 3 packages, and audited 114 packages in 940ms

found 0 vulnerabilities
```

## O navegador

O pacote não contém navegador. Cada versão do Playwright é testada contra um build de cada navegador,
e ele baixa esse build para uma pasta só dele, separada de qualquer navegador que você usa para
navegar. Isto pergunta a ele onde, e o quê, sem baixar nada:

```
ana@dev:~/planner$ env -u PLAYWRIGHT_BROWSERS_PATH npx playwright install --dry-run chromium
Chrome for Testing 153.0.8010.12 (playwright chromium v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip

Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip
```

**O Chromium 153.0.8010.12** é o build que a 1.63.0 aponta, e o headless shell é o mesmo navegador
compilado para rodar sem janela, que é como os testes rodam por padrão. Na sua máquina o download é um
comando, rodado no projeto:

```sh
npx playwright install --with-deps chromium
```

O `chromium` limita o download ao único navegador que este curso usa; o Playwright também controla o
Firefox e o WebKit, o motor do Safari, e um projeto que dá suporte a eles deve testar neles também. O
`--with-deps` instala as bibliotecas de sistema de que o Chromium precisa, e no Linux pede a sua senha
para isso. No Windows e no Mac não é preciso nada a mais.

*Esse comando não foi rodado onde este curso foi gravado: a máquina de gravação não alcançava o
servidor de download do Playwright, e já tinha exatamente este build, o 1243, que toda transcrição do
curso usou.* É também por isso que o curso fixa a 1.63.0 e não a versão mais nova: um Playwright mais
novo aponta um build mais novo, e as transcrições teriam vindo de um navegador com que ele não foi
testado.

## Numa máquina virtual

O navegador roda sem janela, então um servidor sem área de trabalho roda estes testes exatamente como
um notebook. O que ele não consegue é mostrar a página, e duas coisas nesta aula são sobre vê-la: o
visualizador de trace e o relatório, que abrem num navegador seu. Numa máquina virtual, copie a pasta
do relatório para o seu computador e abra lá.
