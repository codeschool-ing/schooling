---
title: Quatro registros de uma mudança
version: 1
---

**Uma auditoria responde quatro perguntas sobre uma mudança: quem, o quê, quando e por quê.** Num
arranjo GitOps nenhum sistema sozinho responde as quatro, e isso é de propósito: cada passo de uma
mudança acontece num lugar diferente, e cada lugar guarda o próprio registro.

| o registro | ele diz | ele não sabe dizer |
|---|---|---|
| **o Git e o pull request** | quem escreveu a mudança, quem aprovou, por quê, em texto | se ela chegou a algum cluster |
| **os eventos do Flux** | qual revisão foi aplicada, quando, e se deu certo | quem a escreveu |
| **o log de auditoria do API server** | cada pedido ao cluster: quem, qual objeto, qual verbo | de qual commit veio um pedido |
| **o log de auditoria do Vault** | cada pedido de segredo: qual identidade, qual caminho | para que o segredo foi usado |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Quatro registros de uma mudança, ligados por identificadores. Um pull request no Git registra o autor, quem revisou e o motivo, e produz um hash de commit. Os eventos do Flux registram que a revisão do commit foi aplicada, quando, e o resultado. O log de auditoria do API server registra cada pedido que o controlador do Flux fez, sob a ServiceAccount do controlador. O log de auditoria do Vault registra cada leitura feita pela ServiceAccount de um pod. O hash do commit liga os dois primeiros, a identidade do controlador liga o segundo e o terceiro, e a ServiceAccount do pod liga o cluster ao Vault.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"90.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"90.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">autor, revisão, motivo</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"270.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">eventos do Flux</text><text x=\"270.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">revisão aplicada</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"450.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">auditoria do API server</text><text x=\"450.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">todo pedido</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"630.0\" y=\"70.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">auditoria do Vault</text><text x=\"630.0\" y=\"88.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">toda leitura</text><line x1=\"160\" y1=\"75\" x2=\"190.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"198,75 190.0,70.5 190.0,79.5\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"75\" x2=\"370.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"378,75 370.0,70.5 370.0,79.5\" fill=\"var(--paper-dim)\"/><line x1=\"520\" y1=\"75\" x2=\"550.0\" y2=\"75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"558,75 550.0,70.5 550.0,79.5\" fill=\"var(--paper-dim)\"/><text x=\"180\" y=\"150\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">ligados pelo hash do commit</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">ligados pela ServiceAccount do controlador</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"11\" fill=\"var(--paper-dim)\">ligados pela ServiceAccount de um pod</text><line x1=\"180\" y1=\"138\" x2=\"180\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/><line x1=\"360\" y1=\"168\" x2=\"360\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/><line x1=\"540\" y1=\"198\" x2=\"540\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"/></svg>", "caption": "Nenhum registro responde sozinho quem, o quê, quando e por quê. Cada um carrega um identificador que o próximo também carrega, e auditar é seguir esses identificadores.", "same": ["Git"]}
```

**O fio que passa por eles é um identificador que cada um carrega para o próximo.** O hash do commit
está no pull request e na revisão do Flux. O controlador do Flux é o usuário no log de auditoria do
API server para tudo o que ele aplicou, e a ServiceAccount de um pod é a identidade no log do Vault
para tudo o que ele leu. Seguir o fio é como "quem mudou o token de produção na terça" ganha uma
resposta em vez de um palpite.

Duas coisas não estão nesta tabela porque não merecem estar. **Uma mudança feita com `kubectl` por
uma pessoa** aparece no log do API server e em nada mais: não há pull request, motivo nem revisão.
As aulas 1 e 4 mostraram o Flux desfazendo mudanças assim; esta aula mostra como achar quem as fez.
E **o valor de um segredo** não está em nenhum desses, de propósito: todo registro aqui diz que algo
foi lido ou escrito, nunca o quê.
