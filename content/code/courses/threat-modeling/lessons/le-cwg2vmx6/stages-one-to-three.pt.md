---
title: Estágios 1 a 3, o negócio e o sistema
version: 1
---

Os três primeiros estágios constroem o contexto contra o qual todo o resto é julgado. Na Vereda
levaram uma manhã, com o daniel na sala para o primeiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-first-stages\" aria-label=\"O que os três primeiros estágios do PASTA produziram na Vereda. Estágio 1, objetivos: cerca de 60% dos agendamentos passam pelo portal, e dado de saúde é sensível pela LGPD. Estágio 2, escopo técnico: o que é modelado e o que não é, como o Wi-Fi e os laptops das clínicas. Estágio 3, decomposição: o DFD da aula 2, com os casos de uso ao lado.\"><defs><marker id=\"l04-first-stages-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · objetivos</text><text x=\"125.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">60% dos agendamentos</text><text x=\"125.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pelo portal</text><text x=\"125.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dado de saúde é</text><text x=\"125.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sensível (LGPD)</text><path d=\"M230.0 110.0 L255.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-first-stages-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · escopo técnico</text><text x=\"360.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que é modelado,</text><text x=\"360.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e o que não é:</text><text x=\"360.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o Wi-Fi e os laptops</text><text x=\"360.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">das clínicas</text><path d=\"M465.0 110.0 L490.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-first-stages-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · decomposição</text><text x=\"595.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o DFD da aula 2</text><text x=\"595.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e os casos de uso</text><text x=\"595.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ao lado dele</text><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">primeiro o negócio, depois o sistema</text></svg>", "caption": "O estágio 1 é o que o STRIDE nunca pede, e é ele que depois decide quais ameaças são caras."}
```

### Estágio 1: definir os objetivos

**Para que serve o sistema, e o que doeria se ele parasse de fazer isso?** A saída é uma lista
curta de objetivos de negócio, os requisitos de segurança e de conformidade que vêm com eles, e uma
primeira declaração de impacto: quanto custa falhar em cada objetivo.

| objetivo | por que importa | conformidade |
|---|---|---|
| pacientes agendam e pagam online | cerca de 60% dos agendamentos passam pelo portal; o resto, por telefone | defesa do consumidor, regras de cartão por meio do gateway |
| dado clínico continua privado | pacientes contam o que não contariam a mais ninguém | a **LGPD**: dado de saúde é *dado pessoal sensível* (art. 5º, II, e art. 11) |
| lembretes chegam aos pacientes | uma sessão perdida é um horário vazio que ninguém paga | nenhuma própria |
| a Vereda cumpre a LGPD | a ANPD pode multar e mandar parar o tratamento | a própria lei |

A tabela é onde o daniel justifica a presença. Uma desenvolvedora não teria escrito que 60% dos
agendamentos passam pelo portal, e é esse número que torna T01 e T10 caras no estágio 7.

### Estágio 2: definir o escopo técnico

**O que exatamente está sendo modelado, e do que é feito?** Os componentes, a infraestrutura onde
rodam, os terceiros e as dependências que vêm com cada um. Na Vereda: o portal, o console da
equipe e o worker, a conta de nuvem onde rodam, o banco gerenciado, o armazenamento de objetos, o
provedor de SMS e o gateway de pagamento, e as bibliotecas que cada processo importa. A biblioteca
de PDF que o console usa para mostrar exames está nessa lista, e foi assim que a T14 ganhou nome.

O estágio 2 também anota **o que está fora do escopo**: o Wi-Fi e os notebooks das próprias
clínicas, de que o bruno cuida à parte. Fora do escopo é uma decisão, e anotá-la impede que o
modelo seja culpado depois por algo que ele nunca cobriu.

### Estágio 3: decompor a aplicação

**Como o dado se move, e onde a confiança muda?** Esta é a aula 2: o DFD de nível 1, as fronteiras
de confiança, os atores e os pontos de entrada. O PASTA acrescenta uma lista de **casos de uso**
ao lado do desenho, porque o estágio 6 vai precisar deles: "um paciente agenda e paga", "um
fisioterapeuta abre um exame", "o worker manda os lembretes de amanhã". Cada caso de uso é um
caminho pelo DFD, e cada um será lido de trás para a frente no estágio 6 como a rota que alguém
poderia abusar.

A Vereda já tinha o estágio 3 pronto quando começou o PASTA. É o caso comum: uma equipe que já
desenha DFDs adota o PASTA acrescentando estágios em volta do trabalho que já faz.
