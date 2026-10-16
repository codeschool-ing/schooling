---
title: A qualidade não é o canto livre
version: 1
---

Quem já trabalhou num projeto conhece o triângulo: escopo, prazo e custo, em que fixar dois move o
terceiro. Ele costuma ser creditado a Martin Barnes, que o desenhou em 1969, e muitas versões põem a
qualidade no meio ou a acrescentam como quarto canto. **O problema começa quando a qualidade vira a
variável que absorve tudo o que os outros três não conseguem.** O prazo está fixo, o orçamento está
fixo, o escopo foi prometido, então o time anda mais rápido pulando os testes e o design. Esta seção
argumenta que, para o tipo de qualidade que o cliente não vê, essa troca deixa de compensar em
semanas.

## Dois tipos de qualidade

**A qualidade externa é o que o usuário vê**: se o app do Driver trava, se uma cotação está certa,
quão rápido o mapa do embarcador carrega. Ela pode ser trocada legitimamente. Uma tela mais simples
ou menos opções na primeira versão é um escopo menor, e o negócio tem direito de escolher um escopo
menor.

**A qualidade interna é o que só quem desenvolve vê**: se o código é claro, se os módulos têm
fronteiras sensatas, se há testes que tornam uma mudança segura. Nenhum embarcador vai notá-la
diretamente. O que ela decide é quanto custa a próxima mudança, e é por isso que cortá-la não é a
economia que parece.

## A hipótese da resistência do design, de Fowler

Em 2007 Martin Fowler desenhou um gráfico com o tempo num eixo e a funcionalidade acumulada, o total
do que foi entregue, no outro. Ele tem duas linhas. Uma é um projeto que não dá atenção ao design; a
outra é um projeto que mantém o design saudável enquanto avança.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de funcionalidade acumulada contra o tempo, com duas linhas. A linha sem design começa mais alta e vai ficando mais plana com o tempo. A linha com bom design começa mais baixa e segue reta. Elas se cruzam na linha de retorno do design. Antes dela, economizar entrega mais; depois dela, a diferença cresce toda semana.\"><defs><marker id=\"stamina-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 270 L690 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#stamina-ah)\"></path><path d=\"M80 270 L80 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#stamina-ah)\"></path><text x=\"690\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tempo</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">funcionalidade acumulada</text><path d=\"M80.0 270.0 L95.0 254.1 L110.0 246.7 L125.0 240.9 L140.0 235.9 L155.0 231.4 L170.0 227.4 L185.0 223.6 L200.0 220.1 L215.0 216.7 L230.0 213.6 L245.0 210.5 L260.0 207.6 L275.0 204.8 L290.0 202.1 L305.0 199.4 L320.0 196.9 L335.0 194.4 L350.0 192.0 L365.0 189.7 L380.0 187.4 L395.0 185.1 L410.0 182.9 L425.0 180.8 L440.0 178.6 L455.0 176.6 L470.0 174.5 L485.0 172.5 L500.0 170.6 L515.0 168.6 L530.0 166.7 L545.0 164.8 L560.0 163.0 L575.0 161.1 L590.0 159.3 L605.0 157.6 L620.0 155.8 L635.0 154.1 L650.0 152.4 L665.0 150.7 L680.0 149.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M80 270 L680 72.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M280.8 270 L280.8 44\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><text x=\"288.8458033442822\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">linha de retorno do design</text><text x=\"650\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">bom design</text><text x=\"676\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">sem design</text><text x=\"180\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">antes dela, economizar</text><text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entrega mais</text><text x=\"500\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">depois dela, a diferença</text><text x=\"500\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cresce toda semana</text></svg>", "caption": "A hipótese da resistência do design, de Fowler, redesenhada. O argumento inteiro é onde a linha tracejada cai, e Fowler a põe a semanas do início do projeto, não a meses."}
```

A linha sem design começa mais rápida, porque nenhum tempo vai para o design. Depois ela entorta:
cada funcionalidade nova leva mais tempo que a anterior, à medida que o código fica mais difícil de
entender e de mudar. A linha com bom design começa mais devagar e mantém a inclinação. As duas se
cruzam no que Fowler chamou de linha de retorno do design. **Antes da linha, economizar no design
entrega mais. Depois dela, o projeto que economizou está atrás, e fica mais atrás a cada semana.**

Fowler a chamou de hipótese de propósito. A produtividade em software não pode ser medida bem o
bastante para prová-la, então ela se apoia na experiência de quem já trabalhou nos dois tipos de
código. A parte que mais importa para uma arquiteta é onde a linha cai. Num ensaio posterior, "Is
High Quality Software Worth the Cost?", de 2019, Fowler argumentou que ela chega em semanas, não em
meses, muito antes do que a maioria das pessoas imagina quando decide cortar caminho.

## O que isso quer dizer diante de um prazo

Se a linha de retorno está a semanas, cortar qualidade interna para cumprir uma data só compensa em
trabalho cuja vida acaba antes da linha: um protótipo que vai para o lixo, uma demonstração para uma
reunião, um script de migração que roda uma vez. Para qualquer coisa que vai mudar de novo, e na
Carreto isso é quase tudo, o atalho é pago dentro do mesmo trimestre, com juros.

A Carreto viveu isso no segundo trimestre de Renata. Helena Prado queria cargas com várias paradas,
em que um caminhão coleta de dois embarcadores na mesma viagem, até o fim do trimestre. O time de
Pricing estimou duas maneiras de construir:

- **6 semanas** com testes, estendendo o modelo de cotação para que uma carga tenha uma lista de
  paradas;
- **4 semanas** tratando uma segunda parada como caso especial dentro do código atual de parada
  única, com poucos testes.

A segunda economiza duas semanas. Mas os dois próximos itens do roadmap de Pricing, cargas de retorno
e cotações para carga refrigerada, mexem no mesmo código, e o time estimou que cada um levaria de 2 a
3 semanas a mais em cima do caso especial. **Na ponta baixa dessa estimativa, as duas semanas somem
com a primeira funcionalidade, e a segunda é prejuízo puro.** Renata não decidiu nada aqui. O que ela
fez foi pôr as três estimativas numa página, onde Helena pudesse ver a segunda e a terceira
funcionalidades ao lado da primeira. Helena escolheu as seis semanas.

## De onde o tempo vem de verdade

Se a qualidade interna não é o canto livre, outra coisa precisa se mover quando o prazo aperta. Há
três candidatos honestos.

**Escopo.** Construir menos, ou uma versão menor primeiro. É o canto que se move com mais frequência,
e a próxima seção trata de movê-lo bem.

**Prazo.** Mudar a data. Às vezes é possível e ninguém perguntou. Às vezes, como mostra o caso
regulatório da próxima seção, a data é de alguém de fora da empresa e nada vai movê-la.

**Custo.** Pôr mais gente. Isso funciona muito menos do que promete, e Fred Brooks, cujo ensaio abriu
a aula 12, deu o motivo em *The Mythical Man-Month*, de 1975: acrescentar gente a um projeto de
software atrasado o atrasa mais. Quem entra precisa aprender o sistema com quem já está ocupado, e
cada pessoa a mais cria mais caminhos de comunicação. Entre *n* pessoas há *n*(*n* − 1) / 2 pares,
então cinco pessoas têm 10 pares para manter em sintonia e oito pessoas têm 28.

**A qualidade fica fora dessa lista de propósito.** A qualidade interna não é um canto a ser trocado;
é a condição para que as outras três estimativas signifiquem alguma coisa, porque toda estimativa que
um time dá supõe que ele consegue mudar o código na velocidade a que está acostumado. A próxima seção
pergunta o que é bom o suficiente, que é uma pergunta diferente de quanta qualidade dá para cortar.
