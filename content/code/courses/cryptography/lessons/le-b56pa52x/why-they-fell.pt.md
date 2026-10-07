---
title: Como o MD5 e o SHA-1 caíram
version: 1
---

**O MD5 e o SHA-1 não caíram porque alguém os reverteu. Caíram porque pesquisadores aprenderam a
produzir colisões, duas entradas diferentes com o mesmo resumo, muito mais depressa do que o limite
do aniversário permite.** Isso quebrou a única promessa da qual as assinaturas dependem. A
resistência à pré-imagem dos dois continua em grande parte intacta, e é por isso que ambos
sobrevivem onde ninguém precisa de resistência a colisões, e por isso há quem continue a defendê-los
onde alguém precisa.

## Por que uma colisão quebra uma assinatura

Uma assinatura, como a aula 3 a usou, não assina o documento. Assinar diretamente um arquivo de
20 MB com RSA é impossível, então todo esquema de assinatura primeiro calcula o hash do documento e
assina o resumo. A assinatura é, portanto, uma afirmação sobre o resumo, e vale para **qualquer**
documento com esse resumo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um documento passa por uma função de hash e vira um resumo curto; a chave privada assina só o resumo. Um segundo documento, diferente, com o mesmo resumo estaria coberto pela mesma assinatura, e é por isso que um hash que permite colisões quebra as assinaturas.\"><defs><marker id=\"sh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">documento A</text><text x=\"95\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o inofensivo</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">documento B</text><text x=\"95\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um diferente</text><polyline points=\"172,55 258,55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sh-ah-wire)\"></polyline><text x=\"215\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hash</text><polyline points=\"172,165 258,80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#sh-ah-amber)\"></polyline><text x=\"212\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mesmo resumo?</text><rect x=\"260\" y=\"30\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resumo</text><text x=\"340\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">b40d…54fc</text><polyline points=\"422,55 508,55\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#sh-ah-phosphor)\"></polyline><text x=\"465\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">chave privada</text><rect x=\"510\" y=\"30\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">assinatura</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">válida para o resumo</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Se B tem o resumo de A, a assinatura</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">de A também é uma assinatura válida de B.</text></svg>", "caption": "A chave assina o resumo, nunca o próprio documento.", "same": ["hash"]}
```

Então, se alguém consegue produzir dois documentos com o mesmo resumo, um inofensivo e outro não,
uma assinatura obtida no inofensivo também é uma assinatura válida no outro. Nada no algoritmo de
assinatura nem na chave precisa ser fraco. O hash era o elo fraco.

## A linha do tempo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de 1990 a 2030. MD5 publicado em 1992, SHA-1 em 1995, SHA-2 em 2001. Depois colisões de MD5 em 2004, SHA-1 enfraquecido em 2005, o certificado de AC falsa feito com colisões de MD5 em 2008, o Flame em 2012, o SHA-3 em 2015, o SHAttered e os navegadores abandonando o SHA-1 em 2017, o Shambles em 2020, e o prazo do NIST para remover o SHA-1 no fim de 2030.\"><polyline points=\"40,125 690,125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><polyline points=\"40.0,121 40.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"40.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1990</text><polyline points=\"202.5,121 202.5,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"202.5\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2000</text><polyline points=\"365.0,121 365.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"365.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2010</text><polyline points=\"527.5,121 527.5,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"527.5\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2020</text><polyline points=\"690.0,121 690.0,129\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></polyline><text x=\"690.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2030</text><polyline points=\"72.5,119 72.5,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"72.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">MD5</text><polyline points=\"121.25,119 121.25,70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"121.25\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-1</text><polyline points=\"218.75,119 218.75,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"218.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-2</text><polyline points=\"446.25,119 446.25,48\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></polyline><text x=\"446.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SHA-3</text><text x=\"38.0\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">publicados</text><polyline points=\"267.5,131 267.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"267.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">colisões de MD5</text><polyline points=\"332.5,131 332.5,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"332.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">AC falsa</text><polyline points=\"397.5,131 397.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"397.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Flame</text><polyline points=\"478.75,131 478.75,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"478.75\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHAttered</text><polyline points=\"527.5,131 527.5,157\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"527.5\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Shambles</text><polyline points=\"690.0,131 690.0,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"694.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHA-1 removido</text><text x=\"283.75\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SHA-1 enfraquecido</text><polyline points=\"283.75,119 283.75,100\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></polyline><text x=\"38.0\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quebrados, ou aposentados</text></svg>", "caption": "Cada aviso veio uma década antes do ataque que o tornou urgente.", "same": ["Flame", "SHAttered", "Shambles"]}
```

**MD5.** Projetado em 1991 e publicado como RFC 1321 em 1992. Fraquezas no funcionamento interno
foram achadas em 1996, e em 2004 Xiaoyun Wang e colegas publicaram colisões reais de MD5. Em poucos
anos, uma colisão num computador comum levava segundos. Em 2008, uma equipe de pesquisadores usou
colisões de MD5 para obter, de uma autoridade certificadora real que ainda assinava com MD5, um
certificado capaz de agir como uma AC. Eles o fizeram expirar no passado para que não pudesse ser
abusado, e as ACs pararam de usar MD5 em poucas semanas. Em 2012, o malware de espionagem Flame foi
encontrado assinado com um certificado de assinatura de código da Microsoft forjado a partir de uma
colisão de MD5 contra uma AC de licenciamento esquecida da Microsoft. Àquela altura o MD5 já estava
descontinuado havia uma década, e esse era o problema: estava descontinuado, não removido.

**SHA-1.** Publicado pelo NIST em 1995. Em 2005, o grupo de Wang mostrou que colisões podiam ser
achadas em cerca de 2⁶⁹ operações, bem abaixo dos 2⁸⁰ do limite do aniversário. O NIST o
descontinuou em 2011. Os navegadores deixaram de confiar em certificados SHA-1 no começo de 2017,
e semanas depois o Google e o CWI de Amsterdã publicaram o **SHAttered**, dois arquivos PDF
diferentes com o mesmo resumo SHA-1, ao custo de cerca de 6.500 anos de tempo de processador e 110
anos de tempo de GPU. Em 2020, o **SHA-1 is a Shambles** demonstrou o tipo mais forte de colisão, em
que as duas entradas podem começar com conteúdos diferentes e escolhidos, por cerca de 45 mil
dólares de GPU alugada, e o usou contra a rede de confiança do PGP. O NIST anunciou que o SHA-1 deve
ser removido por completo até o fim de 2030.

## Dois tipos de colisão, e por que o segundo é pior

Os resultados de 2004 com o MD5 e de 2017 com o SHA-1 eram colisões de **prefixo idêntico**: as duas
entradas começam com o mesmo conteúdo e diferem só em blocos que o atacante calcula. Isso basta para
quebrar um formato capaz de esconder esses blocos, e é assim que dois PDFs de aparência diferente
podem compartilhar um resumo.

Uma colisão de **prefixo escolhido** deixa as duas entradas começarem com conteúdos diferentes
escolhidos pelo atacante, como dois certificados com nomes diferentes. Foi o que a AC falsa de 2008
e o Flame usaram com o MD5, e o que o Shambles trouxe para o SHA-1. Quando uma colisão de prefixo
escolhido fica acessível, tudo o que é assinado sobre aquele hash, por qualquer um que possa ser
levado a assinar a metade inofensiva, passa a ser suspeito.

## O que um defensor tira disso

A lição não é sobre a matemática. É sobre a distância entre um hash ser **mostrado fraco** e ser
**removido**:

- as fraquezas internas do MD5 eram conhecidas **doze anos** antes da AC falsa, e as do SHA-1
  **doze anos** antes do SHAttered. Nas duas vezes, o aviso veio muito antes do ataque;
- os sistemas que mantiveram o hash fraco "porque ninguém o quebrou na prática" foram os expostos
  quando alguém quebrou;
- a solução é inventário: saber onde cada hash é usado e substituí-lo enquanto o ataque ainda é
  teórico. O Git, que identifica cada commit por SHA-1, acrescentou detecção de colisões em 2017 e
  aceita repositórios SHA-256, justamente para que sua mudança não precise acontecer às pressas.

O SHA-256 não tem nenhuma fraqueza conhecida desse tipo hoje. Era o que o MD5 tinha em 1995.
