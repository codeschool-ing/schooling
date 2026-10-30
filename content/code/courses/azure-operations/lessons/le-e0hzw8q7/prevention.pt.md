---
title: Tornando o acidente difícil de acontecer
version: 1
---

Restaurar é uma habilidade; não precisar disso é um desenho. A conta de estado da loja tem cinco proteções, cada uma
contra um jeito diferente de perder o arquivo, e cada uma é uma configuração, e não um hábito.

| proteção | o que ela impede |
|---|---|
| **versionamento de blobs** | uma sobrescrita: o conteúdo anterior fica como versão |
| **exclusão reversível**, 30 dias | uma deleção: o blob e os snapshots podem ser recuperados |
| **um lock `CanNotDelete`** na conta | a própria conta ser apagada, por qualquer um, o portal incluído |
| **acesso por chave desligado**, papel de dados para duas identidades | quem lista chaves ler ou escrever o estado |
| **um grupo de recursos próprio**, `rg-tfstate` | um `destroy` da aplicação levar o próprio registro junto |

A terceira é um **lock de gerenciamento**, um recurso do Resource Manager diferente do lease da lição 6: um lease
guarda o conteúdo de um blob enquanto dura um `apply`, e um lock guarda um recurso contra deleção até alguém com o papel
certo removê-lo. Até um Owner precisa removê-lo antes, e esse é o ponto: apagar a conta de estado vira dois atos
deliberados em vez de um descuidado.

A quarta é a que as equipes pulam. **Duas identidades precisam escrever no estado: a da esteira e uma identidade de
emergência para uma pessoa.** Ninguém mais precisa, e um desenvolvedor que quer ver o que o estado guarda roda
`terraform show` pela esteira em vez de ler o blob. Menos escritores são menos jeitos de gravar o arquivo errado por
cima do certo.

E o hábito por cima das cinco: **uma esteira que roda `apply` tira um snapshot antes.** Custa um comando e alguns bytes,
e transforma o primeiro acidente desta lição numa recuperação de dois minutos mesmo numa conta em que alguém desligou
o versionamento.
