---
title: A caixa de areia, e o que mora nela
version: 1
---

**Num notebook, um programa consegue ler a maioria dos seus arquivos: os seus documentos, as
configurações de outro programa, a pasta que você baixou ontem.** Um celular não funciona assim, e
essa é a primeira coisa sobre armazenamento que vale desaprender. Cada app é instalado numa pasta só
dele, a sua *sandbox*, a caixa de areia, e o sistema deixa o app ler e escrever ali e quase em
nenhum outro lugar. Outro app não consegue abrir os arquivos do planner, e o planner não consegue
abrir os deles.

Daí vêm três consequências, e cada uma molda uma decisão mais adiante nesta aula:

- **Nada mais consegue ler.** A documentação do Android sobre armazenamento específico do app, lida
  em 30 de outubro de 2026, diz isso com todas as letras: outros apps não conseguem acessar arquivos
  guardados no armazenamento interno. Isso faz da sandbox o lugar certo para o plano da aluna, e o
  lugar errado para uma foto que ela espera ver na galeria.
- **Ela vai embora quando o app vai.** Desinstalar um app remove a sandbox dele, nas duas
  plataformas. Um arquivo que o usuário gostaria de manter depois de apagar o app, uma foto ou um
  PDF exportado, pertence ao armazenamento compartilhado, pelos seletores do próprio sistema, que é o
  que os cursos depois da bifurcação ensinam.
- **Ela não é uma pasta única e indivisa.** Lá dentro o sistema tem opinião sobre cada parte: qual
  é copiada para o backup na nuvem do usuário, e qual ele pode esvaziar por conta própria quando o
  disco está ficando cheio.

## As pastas, e a opinião do sistema sobre cada uma

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-sandbox\" aria-label=\"Duas caixas de areia lado a lado. Android, a pasta do próprio app: files, databases e shared preferences, mantidos e copiados pelo Auto Backup; no_backup, mantido e sem backup; cache, sem backup, e o sistema pode apagar quando falta espaço. iOS, o contêiner do app: Documents, os documentos do usuário, mantidos e com backup; Library, Application Support, mantido e com backup; Library, Caches, sem backup, e o sistema pode esvaziar; tmp, sem backup, esvaziado quando o app não está rodando. Outros apps não alcançam nenhum dos dois.\"><rect x=\"14\" y=\"30\" width=\"336\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"30\" width=\"336\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Android: a pasta do próprio app</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS: o contêiner do app</text><rect x=\"26\" y=\"44\" width=\"312\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files/</text><text x=\"38\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">databases/</text><text x=\"38\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shared_prefs/</text><text x=\"330\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mantido · com backup</text><rect x=\"26\" y=\"112\" width=\"312\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">no_backup/</text><text x=\"330\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mantido · sem backup</text><rect x=\"26\" y=\"152\" width=\"312\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cache/</text><text x=\"330\" y=\"167.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o sistema pode apagar</text><rect x=\"382\" y=\"44\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Documents/</text><text x=\"686\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mantido · com backup</text><rect x=\"382\" y=\"90\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Library/Application Support/</text><text x=\"686\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mantido · com backup</text><rect x=\"382\" y=\"136\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Library/Caches/</text><text x=\"686\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o sistema pode apagar</text><rect x=\"382\" y=\"182\" width=\"312\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tmp/</text><text x=\"686\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o sistema pode apagar</text><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">outros apps não entram</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">tudo vai embora quando o app é desinstalado</text></svg>", "caption": "As mesmas três promessas em duas grafias: mantido e com backup, mantido e sem backup, e um cache que o sistema pode esvaziar por conta própria."}
```

**As duas plataformas dão nomes diferentes às pastas e concordam na ideia.** Há um lugar para os
dados do próprio app, que o backup leva, e um lugar para um cache, que o backup pula e o sistema pode
apagar. O iOS acrescenta um lugar para documentos que o usuário fez, que o app Arquivos pode mostrar
a ele se o app permitir. O guia de sistema de arquivos da Apple diz sobre a `tmp/` que o sistema
pode esvaziá-la quando o app não está rodando, e a documentação do Android diz o mesmo do `cacheDir`
quando o aparelho está com pouco espaço.

**"O sistema pode apagar" é a frase que decide onde um arquivo vai.** Ponha o plano de estudos da
aluna no cache e ele funciona perfeitamente por semanas, em todos os testes, até o dia em que o
celular está quase cheio e o sistema limpa os caches para abrir espaço. Nada falha. O plano
simplesmente está vazio, e parece exatamente um plano que ninguém escreveu ainda. É por isso que a
próxima etapa é uma tabela do que vai onde, e por isso ela começa da pergunta *o app conseguiria
fazer isto de novo?*

## O que o planner guarda

O planner tem quatro tipos de coisa para guardar, e cada um cai num lugar diferente:

| o quê | um exemplo | onde vai |
|---|---|---|
| os dados da aluna | cursos e sessões | um banco de dados, na pasta de dados do próprio app |
| configurações pequenas | a última aba aberta, um tema | preferências |
| algo buscado que pode ser buscado de novo | a semana, como o servidor mandou na aula 14 | o cache |
| um segredo | o token que mantém a aluna conectada | o Keychain ou o Keystore, nunca um arquivo |

O resto desta aula trata deles nessa ordem, com um arquivo no seu computador fazendo o papel de cada
um. A sua pasta `~/planner` faz o papel da sandbox: uma pasta que pertence a um programa e que nada
mais lê.
