---
title: Onde as tabelas de correspondência erram
version: 1
---

Uma tabela de correspondência (um crosswalk) é um mapeamento entre frameworks: este controle da ISO é
aquele resultado do CSF é aquele critério do SOC 2. Elas são úteis e estão em toda parte, e cada uma
é a opinião de alguém escrita como tabela. Cinco jeitos de elas enganarem, e o arquivo da Vereda foi
feito para evitar todos.

### 1. Mapeado não é implementado

A falha mais comum. Uma planilha com uma referência em toda linha parece pronta, e um leitor entende
"8.7 → C6" como se a Vereda protegesse contra malware em arquivos de exame. Não protege: o C6 não foi
comprado. **A coluna `plan` está no `mapping.csv` exatamente por isso**, e o `crosswalk.py` imprime
"(not bought)" ao lado do C6 onde quer que ele apareça. Um mapeamento que não mostra o status vai ser
lido como a afirmação de que tudo está no lugar.

### 2. Muitos para muitos, achatado

O C1 responde à 8.5 e ao PR.AA-03. O C7 responde à 5.17, à 8.5 e ao PR.AA-03. A 8.5 é respondida
pelo C1 e pelo C7. Mapeamentos reais são de muitos para muitos, e uma tabela impressa como uma coluna
contra outra força uma referência por linha. Aí alguém lê que a 8.5 é "o C1", conclui que está
coberta e nunca pergunta pela fase 2 do C7.

### 3. O controle do framework é maior que o seu

A 8.5, autenticação segura, trata de tudo sobre como um sistema autentica: métodos, proteção de
credenciais, respostas a falhas, limites de sessão. O C1 é uma parte disso. Dizer que o C1 "mapeia
para" a 8.5 é verdade; dizer que a 8.5 está "feita" porque o C1 existe não é. **Um mapeamento diz onde
um controle está arquivado, não que o arquivo está completo.** A declaração de aplicabilidade, com o
seu "parcial", é onde a completude é argumentada.

### 4. A edição mudou

A ISO 27001 foi revisada em 2022, e todas as referências mudaram:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l13-drift\" aria-label=\"Quatro controles renumerados entre as edições de 2013 e 2022 do Anexo A da ISO 27001. O A.9.4.2, procedimentos de logon seguro, virou 8.5, autenticação segura. O A.9.2.3, gestão de direitos de acesso privilegiado, virou 8.2. O A.13.1.3, segregação de redes, virou 8.22. O A.18.1.4, privacidade e proteção de PII, virou 5.34.\"><defs><marker id=\"l13-drift-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">ISO 27001:2013</text><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ISO 27001:2022</text><rect x=\"20.0\" y=\"40.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.9.4.2</text><text x=\"108.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">procedimentos de logon seguro</text><rect x=\"390.0\" y=\"40.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.5</text><text x=\"450.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">autenticação segura</text><path d=\"M350.0 58.0 L390.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"88.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.9.2.3</text><text x=\"108.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gestão de direitos de acesso privilegiado</text><rect x=\"390.0\" y=\"88.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.2</text><text x=\"450.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">direitos de acesso privilegiado</text><path d=\"M350.0 106.0 L390.0 106.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"136.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.13.1.3</text><text x=\"108.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segregação de redes</text><rect x=\"390.0\" y=\"136.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8.22</text><text x=\"450.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">segregação de redes</text><path d=\"M350.0 154.0 L390.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"184.0\" width=\"330.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A.18.1.4</text><text x=\"108.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">privacidade e proteção de PII</text><rect x=\"390.0\" y=\"184.0\" width=\"310.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5.34</text><text x=\"450.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">privacidade e proteção de PII</text><path d=\"M350.0 202.0 L390.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-drift-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">um mapeamento guardado como números envelhece com a edição contra a qual foi escrito</text></svg>", "caption": "O controle é o mesmo e o número não. Um mapeamento que diz a edição que usou pode ser traduzido; um que não diz está errado em silêncio.", "same": ["ISO 27001:2013", "ISO 27001:2022"]}
```

Um mapeamento escrito em 2020 contra a edição de 2013 não está errado sobre os controles; está errado
sobre os números deles, e um leitor com a edição de 2022 não acha o A.9.4.2 em lugar nenhum.
Mapeamentos que não nomeiam a edição falham assim, em silêncio. Existem tabelas oficiais para alguns
pares, e o NIST publica as referências do seu framework para outros documentos pelo programa OLIR,
mas **uma tabela oficial também é uma opinião**, escrita para uso geral, e cada uma nomeia a edição que
usou.

### 5. O framework vira o modelo

A última e a mais cara. Uma equipe que recebe um questionário de 60 perguntas começa a respondê-las,
e depois de um tempo as 60 perguntas são o modelo de ameaças. Ameaças que ninguém numerou não são
procuradas: nenhum framework sabia que o worker de lembretes da Vereda entrava como dono do banco, e a
T13 foi achada desenhando o DFD, não lendo o Anexo A.

**O sentido do mapeamento é a proteção.** O arquivo da Vereda mapeia para fora, de ameaças para
controles para referências. Uma equipe que mapeia para dentro, de referências para os controles que
der para achar para elas, tem uma tabela perfeita e nenhuma ideia do que pode dar errado no próprio
sistema.
