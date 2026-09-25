---
title: O disco: partições, e o que "limpa" apaga
version: 1
---

**Uma partição é uma fatia do disco que o sistema trata como uma área separada.** Num computador com
firmware UEFI, a instalação do Windows divide em quatro o disco em que instala:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um disco desenhado como uma barra dividida em quatro partições, como a instalação do Windows as cria num computador UEFI. Primeiro a partição de sistema EFI, 100 MB, FAT32, com o carregador de boot. Depois a MSR, 16 MB, reservada e vazia. Depois a partição do Windows, o resto do disco, NTFS, unidade C:, com o sistema, os programas e os arquivos. Por último, uma partição de Recuperação de cerca de 1 GB com o WinRE, usado para reparos. Só a C: aparece no Explorador de Arquivos.\"><defs><marker id=\"lo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um disco, GPT</text><rect x=\"20\" y=\"36\" width=\"90\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"65.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sistema EFI</text><text x=\"65.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 MB, FAT32</text><rect x=\"112\" y=\"36\" width=\"60\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"142.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MSR</text><text x=\"142.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 MB</text><rect x=\"174\" y=\"36\" width=\"420\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"384.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows (C:)</text><text x=\"384.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resto, NTFS</text><rect x=\"596\" y=\"36\" width=\"104\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"648.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recuperação</text><text x=\"648.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cerca de 1 GB</text><path d=\"M65.0 98 L65.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o carregador de boot</text><path d=\"M142.0 98 L142.0 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"142.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reservada, vazia</text><path d=\"M384.0 98 L384.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"384.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema, programas, seus arquivos</text><path d=\"M648.0 98 L648.0 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"648.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">WinRE, para reparos</text><rect x=\"20\" y=\"182\" width=\"28\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"58\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tracejadas: escondidas do Explorador de Arquivos</text></svg>", "caption": "Quatro partições, e o Explorador de Arquivos mostra uma. Apagar as outras três para \"liberar espaço\" é como um PC para de ligar.", "same": ["MSR", "16 MB", "100 MB, FAT32", "Windows (C:)"]}
```

- **Partição de sistema EFI**: pequena, formatada em FAT32 para o firmware conseguir ler, e com o
  carregador de boot da aula 1. Todo sistema da máquina guarda o próprio carregador aqui.
- **MSR** (*Microsoft Reserved*): alguns megabytes que o Windows guarda para si. Não contém nada que
  você vá olhar um dia.
- **Windows**: a unidade **C:**, formatada em **NTFS**, o sistema de arquivos do próprio Windows. O
  sistema, os programas e os arquivos dos usuários moram todos aqui.
- **Recuperação**: o **Ambiente de Recuperação do Windows** (WinRE), um pequeno sistema de reparo que
  inicia quando o Windows não consegue. A aula 17 o usa.

O próprio disco usa uma tabela de partições chamada **GPT**, que o UEFI exige. Computadores mais
antigos usavam **MBR**, limitada a discos de 2 TB, e você ainda vai encontrá-la em máquinas velhas e
pendrives.

## A tela que decide

*Onde você deseja instalar o Windows?* lista toda partição de todo disco. Para instalar limpo num
disco que já tinha Windows, você **exclui cada partição desse disco** até ele aparecer como uma área
só de *espaço não alocado*, seleciona essa área e clica em Avançar; a instalação cria sozinha as
quatro de cima.

É nesse momento que dados se perdem, e se perdem sem mais nenhum aviso. Três hábitos evitam os
acidentes comuns:

1. **Olhe os tamanhos antes de excluir qualquer coisa.** Um computador com dois discos mostra os dois,
   e o segundo muitas vezes tem os arquivos de alguém.
2. **Desconecte os outros discos** (discos externos, segundos discos internos) quando der. A instalação
   não apaga o que não consegue ver.
3. **Nunca apague as partições pequenas de um sistema funcionando** de dentro do Windows para "ganhar
   espaço". Sem a partição EFI a máquina não tem carregador de boot, e sem a de Recuperação não tem
   ferramentas de reparo. A legenda da figura não é piada.
