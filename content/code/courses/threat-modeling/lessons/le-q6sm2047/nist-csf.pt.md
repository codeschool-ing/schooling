---
title: O NIST CSF, e a lacuna que ele mostra
version: 1
---

O NIST Cybersecurity Framework 2.0, publicado em fevereiro de 2024, organiza a segurança em **seis
funções**, cada uma dividida em categorias e estas em resultados, 22 categorias e 106 resultados ao
todo. A aula 15 de `security-fundamentals` passa por elas. Os donos pediram uma página, e as seis
funções cabem numa página, que é por que o contador sugeriu esse formato.

Um resultado tem um id: **PR.AA-03** é o terceiro resultado da categoria de Proteger para gestão de
identidade, autenticação e controle de acesso, e diz "usuários, serviços e hardware são
autenticados". Esse id é o que o `mapping.csv` guarda.

### Os controles, por função

```
(.venv) ana@vm:~/tm/portal-model$ python3 crosswalk.py csf
Govern         0
Identify       0
Protect        6
  PR.AA-03  C1  C7
  PR.AA-05  C4  C5  C11
  PR.DS-02  C3  C8
  PR.IR-01  C2
  PR.IR-04  C9  C10
  PR.PS-05  C6 (not bought)
Detect         0
Respond        0
Recover        0
```

**Todos os onze controles estão em Proteger.** Não a maioria: todos. E dentro de Proteger, a única
categoria que nada alcança é a PR.AT, conscientização e treinamento, vazia pelo mesmo motivo que a
6.3 estava no Anexo A.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l13-csf-functions\" aria-label=\"As seis funções do NIST CSF 2.0 e as suas 22 categorias, com as categorias que os controles da Vereda alcançam. Governar: 0 de 6. Identificar: 0 de 3. Proteger: 4 de 5. Detectar: 0 de 2. Responder: 0 de 4. Recuperar: 0 de 2.\"><rect x=\"30.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">GV</text><text x=\"80.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Governar</text><rect x=\"50.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"163.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"50.0\" y=\"185.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 de 6</text><rect x=\"142.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"192.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ID</text><text x=\"192.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Identificar</text><rect x=\"162.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"162.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"162.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"192.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 de 3</text><rect x=\"254.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"304.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PR</text><text x=\"304.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Proteger</text><rect x=\"274.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"274.0\" y=\"163.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"304.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 de 5</text><rect x=\"366.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"416.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DE</text><text x=\"416.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Detectar</text><rect x=\"386.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 de 2</text><rect x=\"478.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RS</text><text x=\"528.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Responder</text><rect x=\"498.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"119.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"498.0\" y=\"141.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"528.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 de 4</text><rect x=\"590.0\" y=\"20.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RC</text><text x=\"640.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Recuperar</text><rect x=\"610.0\" y=\"75.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"610.0\" y=\"97.0\" width=\"60.0\" height=\"16.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">0 de 2</text></svg>", "caption": "Toda categoria que os controles alcançam está em Proteger. Um modelo de ameaças pergunta o que pode dar errado num projeto, e as respostas são quase sempre jeitos de impedir; perceber e se recuperar são perguntas que ele raramente faz."}
```

### Por que um modelo de ameaças pende para esse lado

Esta é a coisa mais útil que o mapeamento mostrou até aqui, e é uma propriedade do método, não da
Vereda. Um modelo de ameaças é construído na fase de projeto, a partir de um desenho, e pergunta **o
que pode dar errado** nele. A resposta natural a "isso pode dar errado" é "então impeça", e toda
resposta desse formato é um resultado de Proteger.

As outras três funções respondem a perguntas que o modelo nunca fez:

| função | a pergunta | o que seria para a T03 |
|---|---|---|
| **Detectar** | como saberíamos que aconteceu? | um alerta quando uma conta da equipe entra de fora das clínicas, ou abre muito mais prontuários que num dia normal |
| **Responder** | o que fazemos na primeira hora? | quem pode encerrar as sessões de uma conta da equipe, e quem avisa o daniel |
| **Recuperar** | como voltamos? | restaurar uma anotação clínica que um intruso mudou, e avisar os pacientes que a LGPD diz que precisam ser avisados |

Nada disso está no plano, e parte seria barata. Para a T03, um alerta de login da equipe são poucas
linhas na configuração de log do console. Ele não reduz a chance do ataque, e é por isso que o
ranking de custo da aula 11 não podia vê-lo. **Um controle de detecção reduz o custo do ataque
encurtando-o**, e o modelo estimou eventos de perda sem perguntar quanto tempo cada um duraria até
alguém perceber.

### O próprio trabalho do modelo, no CSF

Duas funções parecem vazias só porque o `mapping.csv` mapeia controles. O trabalho de construir o
modelo é em si um conjunto de resultados, e eles estão em Identificar e Governar:

| resultado | o que diz | onde está neste curso |
|---|---|---|
| ID.RA-03 | ameaças internas e externas são identificadas e registradas | `threats.csv`, aulas 3 a 7 |
| ID.RA-04 | impactos e probabilidades potenciais são identificados e registrados | `risks.csv`, aula 9 |
| ID.RA-05 | ameaças, vulnerabilidades, probabilidades e impactos são usados para entender o risco inerente e orientar a priorização | `fair.py`, `prioritise.py`, aulas 10 e 11 |
| ID.RA-06 | respostas a riscos são escolhidas, priorizadas, planejadas, acompanhadas e comunicadas | o plano em duas fases, e `decisions/` |
| GV.RM-02 | declarações de apetite e de tolerância a risco são estabelecidas, comunicadas e mantidas | os 10% em R$ 500.000 do daniel, aula 10 |

Então a página dos donos tem dois tipos de linha. Proteger, Identificar e Governar têm respostas de
verdade, com ids por trás. **Detectar, Responder e Recuperar dizem "ainda não"**, e dizem num formato
que os donos conseguem ler: um perfil alvo com essas três preenchidas é a próxima coisa que vale
discutir.
