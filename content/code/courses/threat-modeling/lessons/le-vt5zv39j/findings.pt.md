---
title: Achados, e o que fazer com eles
version: 1
---

Uma auditoria termina em achados, e um achado tem uma forma. Aprender a forma é útil dos dois lados
da mesa: é como um auditor escreve, e é como uma revisão de prontidão também deve escrever, para o que
ela acha em outubro ser lido do jeito que o relatório do auditor seria lido em novembro.

### As cinco partes

A revisão de prontidão da seção anterior achou o RA-002 atrasado. Escrito como achado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-finding\" aria-label=\"As cinco partes de um achado de auditoria, com o RA-002 de exemplo. Condição: o RA-002 vencia para revisão em 2 de outubro e não foi revisto. Critério: riscos aceitos são revistos até a data. Causa: nada lembrou o dono; a checagem é rodada à mão. Efeito: a T06 está aceita com uma estimativa que ninguém confere há seis meses. Recomendação: rodar a checagem numa agenda, e avisar o dono.\"><rect x=\"20.0\" y=\"15.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">condição</text><rect x=\"165.0\" y=\"15.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o RA-002 vencia para revisão em 2 de outubro; não foi revisto</text><rect x=\"20.0\" y=\"65.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">critério</text><rect x=\"165.0\" y=\"65.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">riscos aceitos são revistos até a data (questionário, pergunta 22)</text><rect x=\"20.0\" y=\"115.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">causa</text><rect x=\"165.0\" y=\"115.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada lembrou o dono; o acceptances.py é rodado à mão</text><rect x=\"20.0\" y=\"165.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">efeito</text><rect x=\"165.0\" y=\"165.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a T06 está aceita com uma estimativa que ninguém confere há seis meses</text><rect x=\"20.0\" y=\"215.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">recomendação</text><rect x=\"165.0\" y=\"215.0\" width=\"535.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178.0\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodar a checagem numa agenda, e avisar o dono</text></svg>", "caption": "Um achado sem causa faz corrigirem o sintoma: alguém revê o RA-002 nesta semana, e o RA-001 atrasa em abril."}
```

- **Condição**: o que é o caso. Dito como um fato que qualquer um poderia conferir, com datas.
- **Critério**: o que deveria ser o caso, e onde isso foi prometido. Sem critério não há achado, só
  opinião; aqui é a resposta do questionário de que riscos aceitos são revistos até a data.
- **Causa**: por que a lacuna existe. É a parte mais pulada e a que decide se a correção funciona.
- **Efeito**: o que a lacuna custa, ou poderia custar. Para um achado de segurança, o efeito
  normalmente é um risco que o modelo já sabe nomear: a T06 está aceita com uma estimativa que
  ninguém confere há seis meses.
- **Recomendação**: o que a fecharia, mirando a causa e não a condição.

A causa aqui é que o `acceptances.py` só roda quando alguém lembra de rodá-lo. Corrigir a condição,
rever o RA-002 nesta semana, é necessário e não basta: o RA-001 vence em abril de 2027, e nada em
abril vai ser diferente. Corrigir a causa quer dizer a checagem rodar sozinha e avisar o dono. Esse é
o assunto da aula 15.

### Quão sério

As auditorias classificam os achados, com palavras que variam pelo tipo de auditoria. Uma auditoria
de certificação contra a ISO 27001 tem três classificações. Uma **não conformidade maior** é um
requisito não atendido de jeito nenhum, ou um sistema que falhou. Uma não conformidade menor é um
lapso isolado num requisito que no resto é atendido. Uma observação, ou oportunidade de melhoria,
não exige nada. Uma auditoria de segunda parte como a da operadora usa o que o contrato dela disser,
muitas vezes alto, médio e baixo.

A classificação segue a evidência. A revisão atrasada do RA-002 é um lapso isolado num processo que
existe, com dois outros registros em ordem: um achado menor, ou médio. Se nenhum dos três aceites
tivesse data de revisão, a mesma condição seria sobre a ausência de um processo, e classificada mais
alto.

### A resposta

Todo achado recebe uma **resposta da gestão**: concorda ou discorda, o que vai ser feito, por quem e
até quando. Ela é escrita pelo lado auditado e anexada ao relatório. Para o RA-002:

| | |
|---|---|
| resposta | de acordo |
| ação | rever o RA-002 com o daniel; rodar o `acceptances.py` toda segunda-feira e mandar a saída a cada dono |
| dona | ana |
| data | 31 de outubro de 2026 |

Discordar é permitido, e às vezes certo, quando os critérios foram mal lidos ou a evidência estava
incompleta. Precisa ser argumentado com evidência, na mesma forma.

### De volta ao modelo

**Um achado é informação sobre o modelo**, e o último passo é pô-lo lá. Cada um cai num lugar que o
curso já construiu:

| o que o achado diz | para onde vai |
|---|---|
| uma ameaça que ninguém tinha listado | `threats.csv`, como um id novo, e depois pelos requisitos e estimativas |
| um controle que não funciona como desenhado | a verificação do requisito dele, que estava errada, e a estimativa do risco, que estava baixa |
| uma decisão que não foi cumprida | `decisions/`, como um registro novo que substitui o antigo |
| um processo que só roda quando lembrado | as ferramentas do próprio modelo, para a checagem rodar sozinha |

Um achado arquivado numa pasta de auditoria e fechado por e-mail é um achado que vai ser achado de
novo no ano que vem. Um achado que mudou o modelo é um de que o modelo vai lembrar.
