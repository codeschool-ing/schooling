---
title: Versões, e por que uma cópia do mais recente não basta
version: 1
---

Um backup que guarda só a cópia mais nova responde a *o disco morreu*. Ele não responde a *o
arquivo já estava errado quando foi copiado*, e o segundo é a falha mais comum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"Uma grade de dois arranjos contra quatro momentos no tempo: antes de qualquer coisa, o instante em que os arquivos são criptografados, depois de a cópia rodar, e quando você percebe. Um espelho guarda os arquivos bons nos dois primeiros momentos, só os criptografados depois de a cópia rodar, e nada para onde voltar quando você percebe. Trinta dias de versões guarda os arquivos bons o tempo todo, e os bons e os criptografados depois de a cópia rodar.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Dois arranjos, os mesmos quatro momentos</text><text x=\"245\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes</text><text x=\"369\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no instante em</text><text x=\"369\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que criptografa</text><text x=\"493\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois de a</text><text x=\"493\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cópia rodar</text><text x=\"617\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quando você</text><text x=\"617\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">percebe</text><text x=\"24\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um espelho</text><rect x=\"186\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os arquivos bons</text><rect x=\"310\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"369\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os arquivos bons</text><rect x=\"434\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"493\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só os</text><text x=\"493\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">criptografados</text><rect x=\"558\" y=\"76\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"617\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nada para</text><text x=\"617\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">onde voltar</text><text x=\"24\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">trinta dias de versões</text><rect x=\"186\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"245\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os arquivos bons</text><rect x=\"310\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"369\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os arquivos bons</text><rect x=\"434\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"493\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os dois, e</text><text x=\"493\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com data</text><rect x=\"558\" y=\"158\" width=\"118\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"617\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">os bons,</text><text x=\"617\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">de ontem</text><text x=\"24\" y=\"256\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A diferença não é a frequência com que a cópia roda. É se a cópia substitui ou acrescenta.</text></svg>", "caption": "Um espelho mais rápido chega antes à terceira coluna. Não chega a uma resposta diferente."}
```

Leia a terceira coluna. Um **espelho** — uma cópia que é tornada idêntica cada vez que roda —
alcança o momento depois do estrago e fielmente substitui a cópia boa pela ruim. Rodá-lo com mais
frequência faz isso acontecer mais cedo.

**Versionar** significa que a cópia *acrescenta* em vez de substituir, e guarda os estados
antigos por algum período. Essa propriedade sozinha é o que faz a diferença, e é um ajuste e não
outro produto: quase toda ferramenta de backup tem, e algumas saem de fábrica com ele desligado.

## Quantas versões, e por quanto tempo

Não há número certo e há um formato que funciona:

| | guarde |
|---|---|
| os últimos dias | cada versão |
| o último mês | uma por dia |
| o último ano | uma por semana |
| além disso | uma por mês, se o dado valer |

O raciocínio é que erros recentes são percebidos rápido e erros antigos são percebidos devagar.
Um documento que você quebrou hoje de manhã quer a versão de hoje de manhã; uma fotografia
corrompida dois anos atrás é descoberta quando você vai procurá-la, e uma cópia por mês daquele
ano basta para ter alguma coisa.

**O mínimo que vale chamar de backup são trinta dias de versões diárias.** Abaixo disso, um
problema introduzido numa sexta e percebido depois de um feriado já é a única cópia.

## Com que frequência, honestamente

| | para quem serve |
|---|---|
| **continuamente** | trabalho que você está escrevendo agora, em que uma hora perdida é uma hora de trabalho |
| **diariamente** | quase todo mundo, e é o padrão das ferramentas |
| **semanalmente** | a cópia no disco externo, porque ela precisa de uma pessoa para espetar |
| **mensalmente** | arquivos que não mudam, e mais nada |

**Automático ganha de frequente.** Um backup semanal que acontece vale mais que um diário que
depende de lembrar, e essa é a razão de a cópia na nuvem ser a que sobrevive ao contato com a
vida real.

## Completo, incremental, diferencial

Três palavras na tela de ajustes, e um parágrafo basta:

- Um backup **completo** copia tudo. Lento, grande e autossuficiente.
- Um **incremental** copia o que mudou desde o último backup de qualquer tipo. Rápido e pequeno,
  e uma restauração precisa do completo mais cada incremento desde então.
- Um **diferencial** copia o que mudou desde o último *completo*. Tamanho médio, e uma restauração
  precisa de só duas peças.

As ferramentas modernas em geral fazem incremental com completos ocasionais e escondem a coisa
toda, que é o padrão certo. A única razão de conhecer as palavras é que **uma cadeia longa de
incrementos é uma cadeia longa de coisas que precisam todas estar legíveis**, o que é mais um
argumento para o teste de restauração.

## A que não é sobre software

**Confira que rodou.** Toda ferramenta de backup consegue mandar um aviso ou mostrar um estado, e
toda uma delas também consegue falhar em silêncio por meses com o disco desconectado.

Uma vez por mês, olhe a data do backup mais novo. É essa a manutenção inteira, e é o passo entre
*ter um backup* e *ter tido um backup*.
