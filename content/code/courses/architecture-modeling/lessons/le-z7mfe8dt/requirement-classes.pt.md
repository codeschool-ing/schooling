---
title: Quatro classes de requisito
version: 1
---

**O BABOK classifica os requisitos em quatro tipos, pela necessidade de quem eles expressam e pelo
que descrevem.** A classificação é útil porque impede uma lista de misturar níveis, que é como um
objetivo de negócio acaba ao lado da largura de uma coluna e ninguém sabe dizer qual importa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l07-classes\" aria-label=\"As quatro classes de requisito do BABOK como cadeia. Requisitos de negócio, os objetivos da organização, são atendidos por requisitos de stakeholder, as necessidades dos stakeholders, que são atendidos por requisitos de solução, divididos em funcionais e não funcionais. Ao lado da cadeia, requisitos de transição, necessários só para passar do estado atual ao futuro.\"><defs><marker id=\"l07-classes-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"100.0\" y=\"17.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"33.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Requisitos de negócio</text><text x=\"250.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">objetivos da organização</text><rect x=\"100.0\" y=\"102.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"118.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Requisitos de stakeholder</text><text x=\"250.0\" y=\"131.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">necessidades dos stakeholders</text><rect x=\"100.0\" y=\"187.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"203.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Requisitos de solução</text><text x=\"250.0\" y=\"216.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">o que a solução faz e quão bem</text><rect x=\"100.0\" y=\"249.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">funcionais</text><rect x=\"260.0\" y=\"249.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não funcionais</text><path d=\"M250.0 102.0 L250.0 63.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-classes-am-fill-paper)\"></path><path d=\"M250.0 187.0 L250.0 148.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-classes-am-fill-paper)\"></path><text x=\"258.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">atende ↑</text><text x=\"258.0\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">atende ↑</text><rect x=\"470.0\" y=\"80.0\" width=\"220.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\"></rect><text x=\"580.0\" y=\"111.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Requisitos de transição</text><text x=\"580.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">só para passar do</text><text x=\"580.0\" y=\"138.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">agora ao futuro</text><path d=\"M470.0 125.0 L400.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "A cadeia diz por que cada requisito de solução existe. Os de transição ficam ao lado porque desaparecem quando a mudança termina, e é por isso que são os esquecidos."}
```

| classe | o que descreve | a conciliação |
| --- | --- | --- |
| **requisitos de negócio** | os objetivos e resultados da organização | *O financeiro fecha o mês em até um dia útil depois do último arquivo de liquidação.* |
| **requisitos de stakeholder** | as necessidades de um stakeholder ou grupo, que a solução tem de atender | *Joana consegue ver, toda manhã, cada transação sem par com o motivo de não ter batido.* |
| **requisitos de solução** | as capacidades e qualidades da própria solução | funcional: *o job cruza pagamentos com cartão e Pix pelo id da transação, e reembolsos pelo id original*; não funcional: *a conciliação diária termina até as 07:00 num dia com volume de São João* |
| **requisitos de transição** | o que é preciso para passar do estado atual ao futuro, e só durante esse tempo | *as 214 exceções conhecidas são importadas da planilha de Joana antes da primeira execução*; *por um mês, a conciliação manual e a automática rodam em paralelo* |

## Lendo as classes como cadeia

As classes descem em sequência: um requisito de negócio é atendido por requisitos de stakeholder,
que são atendidos por requisitos de solução. Então a cadeia do alto desta tabela até a base diz **por
que** cada requisito de solução existe. *Cruzar reembolsos pelo id original* existe porque Joana
precisa ver o motivo de cada divergência, o que existe porque o financeiro tem de fechar em um dia.

A divisão da aula 6 está dentro desta: os requisitos de solução do BABOK são os requisitos
funcionais e os atributos de qualidade da aula 6. As restrições da aula 6 costumam vir do contexto,
o sexto conceito central.

## Os requisitos de transição são os esquecidos

Toda lista tem requisitos de negócio, de stakeholder e de solução. **Os requisitos de transição são
a classe que falta, e a que decide se a entrada em produção funciona.** Importar as 214 exceções,
rodar os dois processos em paralelo por um mês, treinar a colega que cobre as férias de Joana,
desligar a exportação antiga: nenhuma dessas é uma capacidade do sistema novo, e cada uma é um motivo
para ele falhar no primeiro dia. Elas desaparecem quando a transição termina, e é exatamente por isso
que precisam ser escritas antes de ela começar.
