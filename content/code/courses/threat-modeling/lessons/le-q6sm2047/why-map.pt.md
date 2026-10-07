---
title: Por que mapear
version: 1
---

Na primeira semana de outubro de 2026, três documentos chegaram à Vereda, e nenhum deles mencionava
uma ameaça. **Uma operadora de saúde** que manda pacientes às clínicas quer renovar o contrato, e
anexou um questionário de 60 perguntas numeradas pela ISO/IEC 27001. **Os donos** pediram ao daniel
uma página sobre onde a segurança está, e o contador deles sugeriu o formato do NIST Cybersecurity
Framework. **O gateway de pagamento**, perguntado pela carla se dava para confiar nos webhooks dele,
mandou o seu relatório SOC 2 Tipo II.

Cada um pergunta pelos mesmos onze controles que o modelo escolheu na aula 11. Cada um pergunta no
seu próprio vocabulário, com os seus próprios números, e espera a resposta arquivada sob eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-one-control\" aria-label=\"Um controle respondendo a três perguntas. À esquerda, a cadeia que o modelo construiu: a ameaça T03, uma recepcionista vítima de phishing sem segundo fator, gera o requisito R05, segundo fator em todo login da equipe, que o controle C1 implementa. À direita, três documentos perguntam pelo mesmo controle nos seus próprios termos: o questionário da operadora, pergunta 14, a equipe usa segundo fator; o controle 8.5 do Anexo A da ISO 27001, autenticação segura; e o resultado PR.AA-03 do NIST CSF, usuários, serviços e hardware são autenticados.\"><defs><marker id=\"l13-one-control-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-one-control-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"18.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">T03</text><text x=\"90.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">equipe vítima de phishing</text><rect x=\"30.0\" y=\"88.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">R05</text><text x=\"90.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundo fator, sempre</text><rect x=\"30.0\" y=\"158.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">C1</text><text x=\"90.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundo fator para a equipe</text><path d=\"M140.0 62.0 L140.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-paper-dim)\"></path><path d=\"M140.0 132.0 L140.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-paper-dim)\"></path><rect x=\"420.0\" y=\"24.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">operadora, pergunta 14</text><text x=\"434.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">“A equipe usa segundo fator?”</text><rect x=\"420.0\" y=\"99.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ISO 27001, Anexo A</text><text x=\"434.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8.5 autenticação segura</text><rect x=\"420.0\" y=\"174.0\" width=\"280.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"434.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NIST CSF 2.0</text><text x=\"434.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PR.AA-03 usuários autenticados</text><path d=\"M250.0 180.0 L330.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M330.0 50.0 L330.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M330.0 50.0 L420.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path><path d=\"M330.0 125.0 L420.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path><path d=\"M330.0 200.0 L420.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-one-control-tm-ah-phosphor)\"></path></svg>", "caption": "O modelo já decidiu o C1, por uma ameaça que ele sabe nomear. O mapeamento só diz onde cada framework arquiva essa decisão.", "same": ["NIST CSF 2.0"]}
```

### O trabalho é o modelo; o mapeamento é uma tradução

Há dois jeitos de responder a um questionário como o da operadora. Um é ler pergunta por pergunta e
inventar uma resposta para cada uma, que é como uma empresa acaba com sessenta promessas que ninguém
ligou a nada. O outro é partir do que já existe, **uma ameaça, um requisito, um controle, um custo**,
e dizer onde cada framework o arquiva.

O segundo é um **mapeamento de controles**: uma tabela de cada controle seu para as referências que
ele atende em cada framework. É feito uma vez e lido muitas. Quando a operadora faz a pergunta 14, "a
equipe usa segundo fator?", a resposta é o C1, com o R05 como requisito, um teste como evidência e a
T03 como a razão de ele existir. Quando os donos perguntam onde a Vereda está em autenticação, a
resposta é o mesmo C1, arquivado sob PR.AA-03.

### O que um mapeamento não é

Um mapeamento não decide nada. Não torna um controle necessário e não faz um existir. As decisões
foram tomadas nas aulas 9 a 12, com perdas esperadas e com a assinatura do daniel, e uma referência
de framework não acrescenta peso a elas.

Ele também não substitui ler os frameworks. As aulas 13 a 15 de `security-fundamentals` ensinam o que
um auditor quer, o que a ISO 27001 e a 27002 contêm e como o NIST CSF é organizado. Esta aula parte
delas e faz uma pergunta mais estreita: **dado um modelo de ameaças, como mostrá-lo a alguém que pensa
num desses frameworks, sem perder o que o modelo sabe?**

### Três frameworks, três coisas diferentes

Os três não são alternativas. São tipos diferentes de documento:

| | o que é | quem confere | o que você recebe |
|---|---|---|---|
| **ISO/IEC 27001** | uma norma para um sistema de gestão, com 93 controles de referência no Anexo A | um organismo de certificação acreditado | um certificado |
| **NIST CSF 2.0** | um framework voluntário de resultados, em seis funções | ninguém, a não ser que um contrato diga | um perfil, atual e alvo |
| **SOC 2** | um relatório de asseguração sobre os controles de uma organização de serviços | uma firma independente de CPAs | um relatório, Tipo I ou Tipo II |

A Vereda não vai buscar nenhum dos três. Ela responde a um questionário construído sobre o primeiro,
reporta aos donos no formato do segundo e lê a cópia de um fornecedor do terceiro. É a posição mais
comum para uma empresa do tamanho dela, e é a que esta aula assume.
