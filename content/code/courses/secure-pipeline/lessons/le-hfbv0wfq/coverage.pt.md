---
title: Cobertura de varredura, e os alvos sem achados
version: 1
---

Todos os outros números desta aula são calculados a partir dos achados. A cobertura é o único que
não é, e é o que diz quanto confiar nos outros. **Um alvo para o qual nenhum scanner olha não produz
achados, e um painel de achados o mostra como limpo.** A cobertura é o número que separa limpo de
não examinado.

### O relatório

```
ana@vm:~/metrics$ python3 measure.py coverage
sast      5 of  8 repos   62%
sca       6 of  8 repos   75%
secrets   7 of  8 repos   88%
image     4 of  6 images   67%
scanned by nothing: legacy-reports, refunds-worker
ana@vm:~/metrics$ cut -d, -f2,3 findings.csv | sort | uniq -c | sort -rn
     67 auth-gateway,repo
     60 billing-api,repo
     57 storefront,repo
     55 linkbox,repo
     54 link-stats,repo
     49 billing-api,image
     46 linkbox,image
     44 storefront,image
     39 auth-gateway,image
     35 invoices,repo
      3 web-assets,repo
      1 target,kind
```

Leia as quatro primeiras linhas como frações, cada uma com o próprio denominador. A análise estática
roda em 5 dos 8 repositórios, a varredura de segredos em 7 de 8, e o scanner de imagens em 4 das 6
imagens. Não existe um número único de cobertura: um repositório com varredura de segredos e nada
mais está coberto contra credenciais vazadas e cego para todo o resto, então tirar a média das quatro
linhas numa porcentagem só esconderia justamente que tipo de cegueira é.

O segundo comando conta achados por alvo, direto do arquivo de achados (a última linha é o
cabeçalho). `legacy-reports` e `refunds-worker` nem aparecem. É isso que um painel feito de achados
vê: onze alvos com achados, e os outros três (dois nomes entre eles) em lugar nenhum. `web-assets`
tem três achados, todos do scanner de segredos, o único apontado para ele, e três não é prova de que
o código dele seja melhor que os 57 do `storefront`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l20-coverage\" aria-label=\"Os catorze alvos do inventário, como caixas dentro de uma fronteira chamada o que existe. Onze deles têm pelo menos um scanner e aparecem nos achados; três, o repositório e a imagem do legacy-reports e a imagem do refunds-worker, não têm nenhum. Uma fronteira menor, chamada o que um painel de achados vê, contém só os onze.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que existe: o inventário, 14 alvos</text><rect x=\"24\" y=\"44\" width=\"480\" height=\"262\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"38\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que um painel feito de achados vê: 11 alvos</text><rect x=\"38\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox</text><text x=\"110.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 55</text><rect x=\"193\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox</text><text x=\"265.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 46</text><rect x=\"348\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link-stats</text><text x=\"420.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 54</text><rect x=\"38\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billing-api</text><text x=\"110.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 60</text><rect x=\"193\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billing-api</text><text x=\"265.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 49</text><rect x=\"348\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">invoices</text><text x=\"420.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 35</text><rect x=\"38\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"110.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 57</text><rect x=\"193\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"265.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 44</text><rect x=\"348\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">web-assets</text><text x=\"420.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 3</text><rect x=\"38\" y=\"246\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">auth-gateway</text><text x=\"110.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 67</text><rect x=\"193\" y=\"246\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">auth-gateway</text><text x=\"265.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 39</text><rect x=\"530\" y=\"78\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">refunds-worker</text><text x=\"612.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 0</text><rect x=\"530\" y=\"142\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">legacy-reports</text><text x=\"612.5\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repositório · 0</text><rect x=\"530\" y=\"206\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">legacy-reports</text><text x=\"612.5\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imagem · 0</text><text x=\"612\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">sem scanner, sem achados, fora do painel</text></svg>", "caption": "Achados vêm só do que é varrido. Os três alvos fora da linha de dentro não têm achados, e um painel feito de achados não consegue distingui-los de alvos limpos."}
```

### O denominador é a parte difícil

Calcular cobertura é uma divisão. Saber pelo que dividir é o trabalho, e é por isso que a maioria dos
programas reporta uma cobertura que não consegue sustentar. O numerador vem de graça: todo pipeline
que roda um scanner sabe que rodou. O denominador tem de vir de fora dos pipelines, porque os alvos
que mais importam são os que nunca tiveram um:

- **Repositórios**: a lista dos repositórios da organização na plataforma de hospedagem, incluindo os
  arquivados e os esquecidos. Uma lista mantida à mão se desatualiza.
- **Imagens**: o que o registry guarda e, acima de tudo, o que está rodando. O cluster sabe quais
  imagens os pods dele rodam; uma imagem que roda sem ter saído de um pipeline é a que mais vale a
  pena achar. A política de admissão da aula 10 recusa imagens de qualquer lugar que não seja o
  registry deste projeto, que é cobertura imposta na porta em vez de medida depois.
- **O que não é código**: um servidor que alguém configurou à mão, um bucket, uma conta de SaaS.
  Isso fica fora do que os scanners deste curso leem, e a aula 11 descreveu os scanners que olham
  para essas coisas.

Nos dados gerados o inventário é uma lista dentro do programa, que é o caso fácil. Numa plataforma
real, montá-lo é um pequeno projeto por si só, e ele se paga na primeira vez que revela um
repositório de que ninguém lembrava.

### Cobertura é um scanner ter rodado, não alguém ter lido

O relatório conta um scanner como cobrindo um alvo quando ele está configurado para rodar ali. A aula
1 começou com um scanner que rodava a cada push e estava vermelho havia um mês. Por este relatório,
aquele alvo estava coberto.

Então a cobertura precisa de uma segunda condição para significar alguma coisa: o resultado do
scanner decide algo. No pipeline deste curso essa condição vem embutida, porque cada estágio é um
portão cujo status de saída quebra o build, alerta ou passa (aula 7). Um scanner que roda como um job
que pode falhar não cumpre a condição, e um relatório de cobertura honesto o conta à parte ou não o
conta.

Mais duas formas de a cobertura se superestimar valem a checagem em dados reais:

- **Um scanner que rodou num commit antigo.** Um repositório varrido uma vez, um ano atrás, aparece
  no numerador para sempre, a menos que o relatório pergunte quando foi a última varredura.
- **Um scanner sem nada para ler.** Análise de composição num repositório sem arquivo de lock reporta
  zero achados, toda vez, e fica idêntica a um resultado limpo.

### O que fazer com o número

Cobertura abaixo de 100% não é um fracasso; é uma lista de trabalho. Os dois alvos que nada varre são
os primeiros itens dela, à frente de qualquer achado do relatório de dívida, porque o que quer que eles
contenham não está contado em lugar nenhum. Um número de cobertura que nunca se move é o sinal de que
a lista não está sendo trabalhada.
