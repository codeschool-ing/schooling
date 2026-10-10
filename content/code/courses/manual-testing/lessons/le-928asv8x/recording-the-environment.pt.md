---
title: Registrar o ambiente em todo relatório
version: 1
---

Um relatório do defeito 9 que diz "as reservas fecham cedo" é verdadeiro e inútil. Rui tentaria no
notebook dele, veria um pedido e fecharia o relatório como não reproduzível, e teria razão. **O
ambiente faz parte dos passos**: para um defeito que mora numa diferença entre máquinas, é a parte
mais importante, e para qualquer outro defeito custa um bloco curto. A aula 15 deu os campos de um
relatório de defeito; esta seção preenche o que é mais fácil de pular.

O hábito errado é incluir o ambiente só quando você já desconfia que ele importa. Até lá você
normalmente já registrou três relatórios sem ele, e um deles era o defeito 9 com outro nome. Registre
toda vez, e registre sempre do mesmo jeito, para que dois relatórios possam ser comparados linha a
linha.

## Cinco leituras que levam um minuto

No boxoffice, o ambiente cabe em cinco leituras, e quatro delas vêm do terminal. No segundo terminal,
com o boxoffice rodando:

```
ana@laptop:~/boxoffice$ python3 --version
Python 3.13.16
ana@laptop:~/boxoffice$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@laptop:~/boxoffice$ date
Sat Oct 10 04:11:20 -03 2026
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/health
ok boxoffice 1.1
```

**A versão do Python** roda o programa, e um defeito que aparece numa versão da linguagem e não em
outra é comum o bastante para ser descartado primeiro.

**O sistema operacional** é a segunda linha. No Linux, o `/etc/os-release` diz qual é. No Mac, o
comando `sw_vers` imprime a versão do macOS, e no Windows, digitar `winver` no menu Iniciar abre uma
janela que a mostra; nenhum dos dois foi executado para este curso.

**O relógio e o fuso**, que o `date` imprime. O `-03` no fim é o fuso, e depois desta aula você sabe
por que ele merece uma linha. Repare também na hora impressa, 04:11, que não é o 14:00 em que o
boxoffice acreditava durante essa captura: `BOXOFFICE_NOW` mexe no relógio da aplicação e em mais
nada. Por isso um relatório também precisa dizer **como o programa foi iniciado**, com cada variável
que você definiu, porque um defeito visto com o relógio fixado é uma observação diferente de um visto
com o relógio real.

**A versão da própria aplicação**, pelo `/health`. É a única leitura que não dá para tirar de
memória, porque o arquivo na sua pasta é o que você salvou por último, e a aula 9 fez uma segunda
versão dele. O rodapé de toda página traz o mesmo número, `boxoffice 1.1`, para quem está testando no
navegador.

**O navegador e a versão dele** são a quinta leitura, e a única que o terminal não dá. Todo navegador
mostra a versão exata numa página Sobre: o Firefox e o Chrome a guardam em Ajuda, no menu principal.
Anote também a largura da janela quando o defeito for de layout, como a aula 7 fez com as telas
estreitas.

## Um bloco para colar

Leituras só servem se chegam sempre no mesmo formato. Guarde um bloco como este num arquivo de texto
e cole em todo relatório, preenchido com os comandos acima:

```
Environment
  application:  boxoffice 1.1 (from /health)
  started with: TZ=UTC BOXOFFICE_NOW=2026-10-10T17:30:00-03:00
  python:       Python 3.13.16
  system:       Ubuntu 24.04.5 LTS, zone -03 (America/Sao_Paulo)
  browser:      <name and version, from its About page>, window <width> px
```

A linha `started with` é a que transforma o defeito 9 de uma discussão em duas execuções que qualquer
um pode repetir. Sem ela, quem lê inicia o boxoffice do jeito normal e recebe um pedido.

**Copie, não redigite.** Uma versão digitada de memória é onde `1.1` vira `1.0` e um relatório
descreve um defeito que aquela versão nunca teve. Cole a saída dos comandos, e se uma leitura parecer
estranha, tire-a de novo em vez de corrigi-la à mão.

## Quanto basta

Nem tudo sobre uma máquina cabe num relatório, e uma página de configurações esconde a única linha que
importa. Uma regra justa é registrar **o que plausivelmente pode diferir entre a sua máquina e a de
quem lê**: versões, o fuso, o idioma do sistema, como o programa foi iniciado e os dados de que você
partiu, que no boxoffice é "um início do zero" e num produto real é o nome de um conjunto de dados
(aula 20). Se um defeito acabar dependendo de algo fora do bloco, acrescente essa linha ao bloco, e
todo relatório depois dele a traz.

E quando um defeito aparece num ambiente e não em outro, **diga os dois**. "Fechada em UTC, aberta em
America/Sao_Paulo, mesmo instante" diz ao Rui onde olhar antes de ele ler mais uma palavra. Um
relatório que registra só o lado que falha o obriga a redescobrir o lado que passa, e isso é a
conversa do "na minha máquina funciona" de novo.
