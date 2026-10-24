---
title: Datas de quem, números de quem
version: 1
---

**O `date`, o `number`, o `currency` e o `percent` formatam para uma localidade, e a padrão do Angular é
`en-US`.** Por isso a semana dizia "October 25, 2026": o inglês americano escreve o mês primeiro. Este
curso é escrito em inglês britânico, e o planner deve dizer o que os leitores dele escreveriam. Um
planner em português ia querer `19 de outubro de 2026`, e vírgulas decimais.

A localidade em que uma aplicação é escrita é a **localidade de origem** dela, definida no
`angular.json`. O `ng config` a escreve:

```
ana@dev:~/planner$ npx ng config projects.planner.i18n.sourceLocale en-GB
```

O build então inclui os dados da localidade, os nomes dos meses, os padrões de data, os separadores, e
a torna o padrão de todo pipe. O servidor de desenvolvimento lê o `angular.json` quando inicia, então
pare-o com `Ctrl-C` e inicie o `npx ng serve` de novo:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text 'app-week p'
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
19 October to October 25, 2026
```

O dia antes do mês, sem vírgula, e nada no template mudou.

**Uma aplicação, uma localidade por build.** Um planner que atendesse leitores em inglês e em
português seria construído duas vezes, uma por localidade, com o `@angular/localize` do Angular
traduzindo também o texto do template; isso é um projeto à parte e fica fora deste curso. Uma
localidade escolhida em tempo de execução, pelo leitor, é possível com o `LOCALE_ID` e um argumento de
pipe, `{{ day | date: 'longDate' : undefined : 'pt' }}`, depois de registrar à mão os dados dessa
localidade; a maioria das aplicações que precisam disso usa o build por localidade, porque ele traduz
tudo, não só as datas.
