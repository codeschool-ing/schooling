---
title: Níveis, do contexto ao detalhe
version: 1
---

Um DFD de um sistema inteiro com todas as funções é ilegível, e um DFD com um círculo só não acha
nada. A saída é desenhar **níveis**: o mesmo sistema com detalhe crescente, cada nível abrindo um
processo do nível de cima.

### Nível 0: o diagrama de contexto

O primeiro desenho mostra **o sistema inteiro como um processo só**, todas as entidades externas
com que ele conversa e os fluxos entre eles. Nada de dentro aparece.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l02-context\" aria-label=\"O diagrama de contexto do portal: o sistema inteiro como um processo só no meio, chamado portal do paciente da Vereda, e as quatro entidades externas em volta. Pacientes mandam agendamentos, pagamentos e exames e recebem páginas. A equipe da clínica cuida da agenda e dos prontuários. O gateway de pagamento recebe cobranças e manda confirmações. O provedor de SMS recebe lembretes.\"><defs><marker id=\"l02-context-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"360.0\" cy=\"140.0\" r=\"62\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"360.0\" y=\"133.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal do</text><text x=\"360.0\" y=\"146.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">paciente Vereda</text><rect x=\"25.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Paciente</text><rect x=\"25.0\" y=\"195.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Equipe da clínica</text><rect x=\"565.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Gateway de pagamento</text><rect x=\"565.0\" y=\"195.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Provedor de SMS</text><path d=\"M155.0 62.0 L305.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><path d=\"M303.0 128.0 L155.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"212.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agendamentos, exames</text><text x=\"236.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">páginas</text><path d=\"M155.0 215.0 L305.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"212.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agenda, anotações</text><path d=\"M418.0 118.0 L565.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><path d=\"M565.0 80.0 L420.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"480.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobranças</text><text x=\"500.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">webhook</text><path d=\"M418.0 165.0 L565.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"500.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lembretes</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Nível 0: um processo, todos os de fora, todo fluxo que entra no sistema.</text></svg>", "caption": "O diagrama de contexto responde a uma pergunta: com o que o sistema conversa? É o primeiro desenho e o que um executivo lê.", "same": ["webhook"]}
```

O diagrama de contexto é barato e acha coisas reais. É onde alguém diz "o provedor de SMS recebe o
nome do paciente e o endereço da clínica, combinamos isso com eles?", e essa é uma pergunta sobre
dado pessoal saindo da empresa, que o LINDDUN da aula 5 faria de novo. É também o desenho para
mostrar ao daniel, que cuida das clínicas: cabe num slide e ele reconhece cada caixa.

### Nível 1: as partes principais

O nível 1 abre o processo único nas partes que importam: o portal, o console da equipe, o worker
de lembretes e os dois repositórios de dados. As entidades externas e os seus fluxos continuam os
mesmos; o que é novo são os fluxos entre as partes, e as fronteiras entre elas. **A maioria dos
modelos de ameaças vive no nível 1**, porque é nele que aparecem as fronteiras de confiança de
dentro do sistema. A próxima seção o desenha.

### Nível 2 em diante: só onde compensa

Um nível 2 abre um processo do nível 1, como o portal nas suas funções de login, agendamento,
upload e pagamento. Vale desenhar **para uma parte que é ao mesmo tempo complexa e exposta**: o
upload do portal, que recebe arquivos de qualquer um, talvez mereça um. O worker de lembretes, que
lê uma tabela e chama uma API, não merece. Abrir todo processo "para ficar completo" é o jeito de
um modelo ficar mais detalhado que o projeto que descreve, o que a aula 1 apontou como sinal de ter
passado do ponto útil.

### Mantendo os níveis coerentes

Um nível não pode contradizer o de cima. Todo fluxo que entra num processo no nível 0 precisa
entrar numa das partes dele no nível 1, com o mesmo rótulo. Quando não entra, ou o nível de cima
esqueceu um fluxo ou o de baixo inventou um, e as duas coisas valem saber. Isso se chama
**balancear** o diagrama, e é uma das poucas verificações que um DFD admite sem uma pessoa lendo.
