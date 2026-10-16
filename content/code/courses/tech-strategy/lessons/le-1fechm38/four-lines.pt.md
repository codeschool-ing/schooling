---
title: As quatro linhas de um custo total
version: 1
---

O time de Plataforma da Coreto roda a própria observabilidade: métricas, logs e traces de todos os
serviços, guardados e pesquisados em máquinas de que o time cuida. Rafaela Nunes, que lidera a
Plataforma, ouviu a pergunta: um serviço de observabilidade hospedado sairia mais barato? O
fornecedor publica o preço — tanto por host, tanto por gigabyte de log — e a comparação parece
coisa de cinco minutos.

**Leva cinco minutos porque compara uma linha de quatro.** Eis essa comparação, para três anos:

| | hospedado | auto-hospedado |
|---|---|---|
| o que a página de preços mostra, três anos | R$ 275.400 | R$ 151.200 |

O serviço hospedado cobra R$ 90 por mês para cada um dos 60 hosts da Coreto (R$ 5.400) e R$ 2,50
por gigabyte para os 900 GB de logs que a Coreto envia por mês (R$ 2.250): R$ 7.650 por mês,
R$ 91.800 por ano. O equivalente na pilha auto-hospedada são as máquinas e o armazenamento em que
ela roda, R$ 4.200 por mês. **Nessa linha, auto-hospedar sai R$ 124.200 mais barato**, e muita
decisão é tomada exatamente aqui.

O custo total de propriedade, o TCO, é a mesma comparação com todas as linhas. São quatro.

## Licença

**O que você paga para ter a coisa**, em geral por mês: uma assinatura, uma taxa por host ou por
usuário, ou, para algo que você mesmo roda, as máquinas e o armazenamento de que precisa. É a linha
que todo mundo vê, porque chega como fatura e alguém precisa aprová-la. É também a linha que o
fornecedor desenha para parecer pequena: cobrada por unidade, por mês, numa moeda de hosts ou
gigabytes cujo crescimento ninguém estimou ainda.

Na Coreto, a licença são os R$ 275.400 e os R$ 151.200 acima.

## Integração

**O trabalho antes de qualquer coisa funcionar**: instalar, configurar, ligar ao que já existe,
migrar dados e ensinar as pessoas a usar. É paga uma vez, no começo, em horas.

Ir para o serviço hospedado custaria 320 horas à Plataforma: instalar o agente do fornecedor nos 60
hosts, refazer os painéis e os alertas de que os times dependem e rodar os dois sistemas lado a
lado por tempo suficiente para confiar no novo. A R$ 150 por hora, são **R$ 48.000**. A integração
da pilha auto-hospedada é zero, porque ela já está no lugar — todo serviço já manda métricas e logs
para ela. Essa assimetria é comum: a opção que você tem está sempre integrada, e a opção que você
avalia nunca está.

## Operação

**O tempo que as pessoas gastam mantendo a coisa rodando**, toda semana, enquanto ela existir:
atualizações, capacidade, backups, o alerta de madrugada, as perguntas dos outros times. É paga em
horas, e não para.

Um serviço hospedado também precisa ser operado — alguém administra a conta, os agentes, os acessos
e o volume de logs que define a fatura —, e a Rafaela estima um décimo de engenheiro para isso, 176
horas por ano. A pilha auto-hospedada consome 60% de um engenheiro, 1.056 horas por ano. Em três
anos, a R$ 264.000 o ano de um engenheiro, são **R$ 79.200 no hospedado e R$ 475.200 no
auto-hospedado**. A próxima seção é sobre esta linha, porque é ela que muda a resposta.

## Saída

**Quanto custaria sair**: exportar os dados, substituir a integração, rodar dois sistemas durante
a mudança e cumprir o aviso prévio que o contrato exigir. É paga uma vez, no fim — e é precificada
no começo ou nunca.

Sair do serviço hospedado mais tarde levaria 280 horas (R$ 42.000) para levar painéis, alertas e
agentes para o que viesse depois, mais um mês de licença com os dois rodando, R$ 7.650:
**R$ 49.650**. A planilha da Coreto precifica a saída da pilha auto-hospedada em zero, uma
simplificação a que a última seção desta aula volta.

## Quando cada linha é paga

As quatro linhas caem em momentos diferentes da vida da decisão, e isso é parte do motivo de uma
ser comparada e três serem esquecidas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma linha do tempo de três anos com quatro linhas. Licença: uma barra pelos três anos, paga todo mês numa fatura. Integração: um bloco curto bem no começo, pago uma vez antes de tudo funcionar. Operação: uma barra pelos três anos, paga todo mês em horas de pessoas. Saída: um bloco tracejado depois do ano 3, pago uma vez na saída.\"><text x=\"210\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 1</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 2</text><text x=\"510\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 3</text><path d=\"M135 38 L135 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M285 38 L285 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M435 38 L435 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M585 38 L585 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"122\" y=\"74\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">licença</text><text x=\"122\" y=\"120\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">integração</text><text x=\"122\" y=\"166\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">operação</text><text x=\"122\" y=\"212\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">saída</text><rect x=\"135\" y=\"56\" width=\"450\" height=\"26\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"360\" y=\"73\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">todo mês, numa fatura</text><rect x=\"135\" y=\"102\" width=\"30\" height=\"26\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"175\" y=\"119\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma vez, antes de tudo funcionar</text><rect x=\"135\" y=\"148\" width=\"450\" height=\"26\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"360\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">todo mês, em horas de pessoas</text><rect x=\"590\" y=\"194\" width=\"40\" height=\"26\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"211\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma vez, na saída</text></svg>", "caption": "Quando cada uma das quatro linhas é paga. Uma comparação de preço vê a barra de cima. A integração é paga antes de tudo funcionar, a operação todo mês em horas, e a saída uma vez, na hora de sair."}
```

Uma comparação de preço vê a barra de cima. A integração é gasta antes do primeiro painel útil, a
operação é gasta em horas que ninguém fatura, e a saída é gasta por quem estiver no cargo quando a
empresa decidir sair — muitas vezes alguém que não estava lá quando ela assinou.

Uma regra mantém as quatro honestas: **toda linha em horas é convertida pela mesma taxa**, aqui os
R$ 150 da Coreto, e toda linha cobre o mesmo horizonte, aqui três anos. Uma planilha que converte a
fatura do fornecedor em reais e deixa as horas de operação em horas comparou dinheiro com tempo, e
horas deixadas em horas parecem pequenas ao lado de um valor em reais.
