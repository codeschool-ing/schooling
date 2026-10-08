---
title: O que a LGPD pede
version: 1
---

Tudo até aqui foi sobre sistemas. Esta aula é sobre **pessoas**: as que tinham dados no servidor de arquivos, e o que
a empresa deve a elas agora. No Brasil isso é definido pela **LGPD**, a Lei Geral de Proteção de Dados Pessoais (Lei
13.709/2018), e pelas normas da **ANPD**, a Autoridade Nacional de Proteção de Dados, que a fiscaliza. O que segue é
como um analista de SOC deve entender essas regras, para entregar os fatos certos a quem as aplica. **As decisões
desta aula são do encarregado e do advogado**, e nada aqui é orientação jurídica para um caso real.

Quatro partes da lei importam num incidente:

| onde | o que diz |
|---|---|
| **art. 46** | a empresa que decide como os dados pessoais são usados, o **controlador**, precisa protegê-los com medidas de segurança |
| **art. 48** | o controlador precisa comunicar à ANPD e às pessoas envolvidas um incidente de segurança **que possa lhes acarretar risco ou dano relevante** |
| **art. 41** | o controlador nomeia um **encarregado**, o DPO, que é o canal com a ANPD e com as pessoas cujos dados ele guarda |
| **art. 52** | as sanções da ANPD, de advertência a multa de até 2% do faturamento da empresa no Brasil, limitada a R$ 50 milhões por infração |

O artigo 48 deixou os detalhes para a ANPD, que os definiu na **Resolução CD/ANPD nº 15, de 2024**, o *Regulamento de
Comunicação de Incidente de Segurança*, normalmente chamado de **RCIS**. Ele diz quando um incidente precisa ser
comunicado, até quando, o que a comunicação contém, e o que precisa ser registrado, comunicado ou não.

A decisão que o resto desta aula acompanha tem três perguntas, em ordem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um caminho de decisão de cima para baixo. O incidente envolveu dados pessoais? Se não, registre e pare. Se sim, ou talvez: pode causar risco ou dano relevante às pessoas a que se refere? Se não, registre, com o raciocínio, e guarde o registro por cinco anos. Se sim: comunique à ANPD e às pessoas afetadas em até três dias úteis desde o conhecimento, complemente em até vinte, e registre também.\"><rect x=\"160\" y=\"10\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dados pessoais envolvidos?</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim, ou talvez</text><path d=\"M360 60 L360 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 90 L364.0 82.0 L356.0 82.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"160\" y=\"90\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">risco ou dano relevante às pessoas?</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">critérios do RCIS</text><path d=\"M560 35 L600 35\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 35 L592.0 31.0 L592.0 39.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"610\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não: registrar</text><path d=\"M560 115 L600 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 115 L592.0 111.0 L592.0 119.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"610\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não: registrar por quê</text><path d=\"M360 140 L360 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 170 L364.0 162.0 L356.0 162.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"160\" y=\"170\" width=\"400\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">comunicar: ANPD e as pessoas</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 dias úteis; complemento em até 20</text><rect x=\"10\" y=\"246\" width=\"700\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o registro de incidentes: todo ramo, guardado por cinco anos</text></svg>", "caption": "Todo ramo termina no registro. Só um deles também termina numa comunicação."}
```

Repare na última caixa. **Todo ramo termina no registro**, inclusive "sem dados pessoais" e "sem risco relevante".
Uma decisão de não comunicar continua sendo uma decisão, e precisa ser escrita com os motivos.
