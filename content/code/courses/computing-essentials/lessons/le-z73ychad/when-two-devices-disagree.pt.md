---
title: Quando dois aparelhos discordam, e por que ninguém consegue resolver
version: 1
---

A sincronia mantém cópias idênticas carregando mudanças entre elas. Isso funciona enquanto as
mudanças chegam uma de cada vez. Quando duas chegam de lugares diferentes, descrevendo versões
diferentes do mesmo arquivo, **não existe resposta correta** — o serviço não tem como saber qual
de duas intenções humanas deve ganhar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Três passos numerados descrevendo como um conflito acontece: o notebook fica offline com o arquivo aberto, o arquivo é editado também no desktop, e então o notebook reconecta. Abaixo, três linhas nomeiam o que cada serviço faz: o OneDrive guarda os dois e marca um com o nome do aparelho, o Drive guarda os dois como versões separadas, e o iCloud guarda os dois e acrescenta um número. Uma nota diz que nenhum dos três mescla nada.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Um arquivo, dois aparelhos, e ninguém está errado</text><text x=\"44\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1</text><text x=\"70\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o notebook fica offline com o arquivo aberto</text><text x=\"44\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">2</text><text x=\"70\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o mesmo arquivo é editado no desktop</text><text x=\"44\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3</text><text x=\"70\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o notebook reconecta</text><path d=\"M24 158 L696 158\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"24\" y=\"176\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">OneDrive</text><text x=\"676\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guarda os dois, um marcado com o nome do aparelho</text><rect x=\"24\" y=\"214\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Drive</text><text x=\"676\" y=\"229\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guarda os dois, como versões separadas de um arquivo</text><rect x=\"24\" y=\"252\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">iCloud</text><text x=\"676\" y=\"267\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guarda os dois, com um número acrescentado a um nome</text><text x=\"24\" y=\"304\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nenhum dos três mescla nada. Os três te entregam dois arquivos e a decisão.</text></svg>", "caption": "O único arranjo que evita isso é editar num lugar de cada vez, ou não ter um arquivo — que é o que os documentos da aula anterior são."}
```

## O que você recebe, e o que fazer com isso

Os três te entregam **dois arquivos e a decisão.** Os nomes diferem — `relatorio (MacBook da
Ana).docx`, `relatorio (1).docx`, uma segunda versão no histórico — e a substância não.

O erro é abrir o mais novo, achar que está certo, e apagar o outro. **O mais velho pode guardar
uma hora de trabalho que o mais novo nunca teve**, porque foi editado no aparelho que estava
offline. Abra os dois. Leva dois minutos e é o único jeito de saber.

Para um arquivo do Word ou do Excel, o *Comparar* da aba Revisão faz isso direito e produz um
documento marcado mostrando cada diferença. É o recurso mais útil do Office que ninguém sabe que
existe.

## Por que acontece mais do que deveria

- **Um arquivo deixado aberto num aplicativo.** Word, Excel e a maioria dos editores seguram o
  arquivo e o reescrevem quando você salva, então um documento aberto em duas máquinas é um
  conflito esperando o segundo salvamento. Fechar o arquivo é o que encerra isso, não fechar a
  tampa do notebook.
- **Uma máquina que dorme em vez de sincronizar.** A mudança fica na fila e é enviada ao acordar,
  o que pode ser depois de outra pessoa ter editado.
- **Duas pessoas numa pasta compartilhada.** A versão mais comum no trabalho, e a razão de a aula
  anterior existir: um documento num servidor não tem arquivos para conflitar.

## A regra

**Um arquivo é editado num lugar de cada vez, ou ele não deveria ser um arquivo.**

Se duas pessoas genuinamente precisam trabalhar em algo ao mesmo tempo, aquilo pertence ao Docs
ou à versão web do Office — onde há uma cópia só e a edição é mesclada conforme acontece. A
sincronia serve para carregar um arquivo entre os *seus próprios* aparelhos, e ela é muito boa
nisso.

## E a que é pior que um conflito

Alguns tipos de arquivo não podem ser conflitados com segurança de jeito nenhum, porque são **um
arquivo guardando um banco de dados**: um `.pst` do Outlook, um arquivo de empresa do QuickBooks,
um banco do Access, uma biblioteca de fotos. Duas máquinas escrevendo num desses por sincronia não
produz duas cópias — produz, possivelmente, uma cópia corrompida.

**Não ponha um arquivo de banco de dados vivo numa pasta sincronizada.** Todo serviço diz isso
numa página de suporte que ninguém lê, e a falha é a única desta aula que perde tudo em vez de
fazer bagunça.
