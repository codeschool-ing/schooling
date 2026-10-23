---
title: O que é uma vulnerabilidade conhecida
version: 1
---

Uma **vulnerabilidade conhecida** é uma falha numa versão específica de um pacote que foi
relatada, confirmada e publicada, em geral com a versão que a corrige. A publicação é o que a torna
"conhecida", e isso corta para os dois lados: quem roda a versão afetada pode descobrir e atualizar,
e todo mundo também pode descobrir. **A janela entre a publicação e a sua atualização é a janela que
importa**, e é por isso que vale automatizar a verificação.

### Os identificadores

A mesma falha aparece em mais de uma base, com mais de um nome. O pip-audit imprime um, e os outros
são apelidos dele:

| identificador | quem atribui | exemplo de formato |
|---|---|---|
| **CVE** | o programa CVE, por autoridades como o GitHub e muitos fornecedores | `CVE-2024-56201` |
| **GHSA** | a base de alertas do GitHub | `GHSA-gmj6-6f8f-6699` |
| **PYSEC** | a Python Packaging Advisory Database, lida pelo PyPI | `PYSEC-2026-1472` |

O **OSV**, o formato Open Source Vulnerabilities, é a forma comum em que a maioria dessas bases
publica, e é o que permite a uma ferramenta ler todas. O PyPI mostra os alertas de uma versão na
página do próprio pacote, e os responde pela API dele, que é onde o pip-audit pergunta por padrão.

### O que um registro diz

Um alerta traz três fatos de que quem desenvolve precisa, e raramente é preciso mais para agir:

- **o intervalo afetado**: quais versões têm a falha;
- **a versão corrigida**: o primeiro lançamento sem ela, o número para onde a versão fixada vai;
- **uma gravidade**, muitas vezes como nota CVSS, que ajuda a ordenar o trabalho quando há muitos.

O que um alerta não diz é **se a sua aplicação usa a parte afetada** do pacote. Às vezes claramente
não usa, e a atualização pode esperar a próxima rotina. Decidir isso é legítimo, e é uma decisão:
fica escrita, com o motivo e uma data para olhar de novo, do jeito que a aula 18 pede numa revisão.
Deixar um alerta sem resposta não é a mesma decisão tomada em silêncio; é decisão nenhuma.
