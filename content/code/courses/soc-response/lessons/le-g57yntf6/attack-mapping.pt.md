---
title: Dar nome com o ATT&CK
version: 1
---

Descrito o comportamento, ele precisa de nomes que todo mundo compartilhe. O **MITRE ATT&CK** é o catálogo
público de comportamentos de adversários, montado a partir de incidentes reais: **táticas** são os objetivos
(Initial Access, Credential Access, Persistence, Lateral Movement, Exfiltration e mais nove), e **técnicas** são
os jeitos de alcançá-los, cada uma com um identificador como `T1110`, e subtécnicas como `T1110.003`. Os
nomes ficam em inglês, como no catálogo, para que qualquer equipe os reconheça.

A quinta, passo a passo, com a técnica de que cada passo é evidência:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"A noite de quinta num eixo de tempo, horário local, com a técnica do ATT&amp;CK de cada passo: 02:10 tentativas em 19 contas, T1110.003 password spraying; 02:33 login como bruno, T1078 contas válidas; 02:35 SSH do gw para o files, T1021.004; 02:41 612 MB enviados por HTTPS, T1048.002; 03:05 login com chave, compatível com T1098.004, chaves autorizadas do SSH.\"><path d=\"M30 70 L690 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 64 L70 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:10</text><rect x=\"8\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tentativas, 19 contas</text><text x=\"70\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1110.003</text><path d=\"M205 64 L205 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"205\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:33</text><rect x=\"143\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">login como bruno</text><text x=\"205\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1078</text><path d=\"M340 64 L340 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:35</text><rect x=\"278\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SSH até o files</text><text x=\"340\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1021.004</text><path d=\"M475 64 L475 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"475\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:41</text><rect x=\"413\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">612 MB saem por HTTPS</text><text x=\"475\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1048.002</text><path d=\"M610 64 L610 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"610\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03:05</text><rect x=\"548\" y=\"90\" width=\"124\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de volta com chave</text><text x=\"610\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">T1098.004</text></svg>", "caption": "Cinco passos, cinco técnicas. A última é inferida de uma linha de log; a aula 17 a confirma no disco."}
```

| passo | técnica | tática |
|---|---|---|
| muitas contas, poucas tentativas em cada | **T1110.003** Password Spraying | Credential Access |
| uma conta real, usada de fora | **T1078** Valid Accounts | Initial Access |
| SSH do `gw` para o `files` | **T1021.004** Remote Services: SSH | Lateral Movement |
| um envio grande por HTTPS para um endereço novo | **T1048.002** Exfiltration Over Asymmetric Encrypted Non-C2 Protocol | Exfiltration |
| um login posterior com uma chave que a conta nunca teve | **T1098.004** Account Manipulation: SSH Authorized Keys | Persistence |

A última linha foi rotulada com cuidado: os logs mostram um **login** com chave, não uma chave sendo
**acrescentada**. A técnica é a melhor explicação da evidência, e a aula 17 a confirma encontrando a chave no
disco do `gw`. **Escreva um mapeamento do tamanho que a evidência sustenta**, e diga quais passos são
inferidos.

Um mapeamento rende de três jeitos. Ele transforma um incidente em **inteligência tática** que outra equipe
usa sem ler os seus logs. Ele mostra **onde há detecção e onde não há**: destes cinco passos, a aula 4 tinha
regra para um. E ele diz a quem escreve regras o que escrever em seguida: aqui, uma regra para a quarta linha
teria alertado sobre a transferência em torno da qual a investigação inteira girou.
