---
title: As edições, uma dentro da outra
version: 1
---

O Windows 11 é vendido em edições que são **o mesmo sistema com mais coisas ligadas**. Subir é uma
troca de licença, não uma reinstalação (seção 05), o que diz o quanto elas são próximas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As edições do Windows desenhadas como caixas uma dentro da outra, cada uma contendo a anterior. Home: a área de trabalho, a Microsoft Store e a criptografia do dispositivo; não entra em nada e não recebe conexões de Área de Trabalho Remota. A Pro acrescenta entrar num domínio ou no Entra ID, Política de Grupo, BitLocker, receber Área de Trabalho Remota, Hyper-V e Windows Sandbox. Enterprise e Education acrescentam o Credential Guard e 36 meses de suporte por atualização de recursos, e são vendidas por assinatura, nunca em loja.\"><defs><marker id=\"ld-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"218\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"70\" y=\"88\" width=\"580\" height=\"142\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"120\" y=\"150\" width=\"480\" height=\"72\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Home</text><text x=\"134\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a área de trabalho, a Microsoft Store, criptografia do dispositivo</text><text x=\"134\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não entra em nada, não recebe Área de Trabalho Remota</text><text x=\"84\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Pro</text><text x=\"84\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ entrar em domínio e no Entra ID, Política de Grupo, BitLocker</text><text x=\"84\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ receber Área de Trabalho Remota, Hyper-V, Windows Sandbox</text><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Enterprise / Education</text><text x=\"34\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ Credential Guard, 36 meses por atualização</text><text x=\"34\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">+ vendido por assinatura, nunca em loja</text></svg>", "caption": "Cada edição é a de dentro e mais um pouco. Para um escritório a linha que importa fica entre a Home e a Pro: entrar na organização fica do lado da Pro.", "same": ["Home", "Pro", "Enterprise / Education"]}
```

| | Home | Pro | Enterprise |
|---|---|---|---|
| entrar num domínio Active Directory | não | sim | sim |
| entrar no Microsoft Entra ID (contas corporativas) | não | sim | sim |
| editor de Política de Grupo (`gpedit.msc`) | não | sim | sim |
| BitLocker, gerenciado | só criptografia do dispositivo | sim | sim |
| receber Área de Trabalho Remota | não | sim | sim |
| Hyper-V, Windows Sandbox | não | sim | sim |
| Credential Guard | não | não | sim |
| memória máxima | 128 GB | 2 TB | 6 TB |
| suporte por atualização de recursos | 24 meses | 24 meses | 36 meses |
| como se compra | em loja, com o PC | em loja, com o PC | por assinatura ou licença por volume |

Alguns termos da tabela:

- O *Active Directory* é o diretório que o Windows Server do próprio escritório mantém, com cada
  usuário e cada PC. O **Microsoft Entra ID** é a mesma ideia mantida pela Microsoft na nuvem, e é nele
  que uma *conta corporativa ou de estudante* entra. Entrar num deles é o que deixa uma organização
  gerenciar um PC.
- A *Política de Grupo* é como configurações são empurradas para muitos PCs de uma vez, e o
  `gpedit.msc` a edita num só.
- A *criptografia do dispositivo* da Home é o BitLocker sem controles: ela se liga sozinha quando o PC
  entra com uma conta Microsoft e guarda a chave de recuperação nessa conta. A Pro dá o BitLocker
  completo, com escolha de onde a chave vai.
- *Receber Área de Trabalho Remota* quer dizer aceitar conexões. A Home consegue se conectar a outro
  PC, mas ninguém consegue se conectar a ela.

A *Education* é a Enterprise com preço para escolas, e a *Pro for Workstations* é a Pro para
máquinas com mais de 2 TB de memória ou mais de dois processadores. Nenhuma das duas é vendida numa loja
comum.
