---
title: Cifragem em repouso, e o roubo que ela impede
version: 1
---

**A cifragem em repouso protege dados guardados de alguém que obtém o armazenamento sem a chave: um
notebook roubado, um disco jogado fora, uma fita de backup perdida no caminho, um snapshot copiado de
uma conta na nuvem.** É a cifragem que os documentos de conformidade mais pedem, e a que mais recebe
crédito por uma proteção que ela não dá.

## Camadas, e quem cada uma detém

Dados em repouso podem ser cifrados em várias camadas, e cada camada tem um momento diferente em que
é decifrada, o que decide contra quem ela protege:

| camada | exemplo | decifrada quando | protege contra |
|---|---|---|---|
| **disco ou volume** | LUKS, BitLocker, FileVault, cifragem de volumes na nuvem | a máquina é desbloqueada | roubo do aparelho ou do disco |
| **arquivos do banco** | TDE no SQL Server, Oracle, MySQL; bancos cifrados na nuvem | o servidor do banco inicia | roubo de arquivos de dados e de backups |
| **coluna ou campo** | pgcrypto, AEAD na aplicação | na aplicação, ou numa consulta com a chave | administradores do banco, injeção de SQL que lê tabelas, dumps vazados |
| **arquivo ou objeto** | backups cifrados, S/MIME (aula 13), age, GPG | quem tem a chave o abre | qualquer um que não seja quem tem a chave |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro camadas empilhadas de baixo para cima: o disco ou volume, decifrado quando a máquina é desbloqueada; os arquivos do banco, decifrados quando o banco inicia; uma coluna, decifrada só por uma consulta ou aplicação que tenha a chave; e um único arquivo ou objeto, decifrado só por quem tem a chave dele. Cada camada, depois de decifrada, é transparente para tudo o que está acima.\"><defs><marker id=\"lay-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"210.0\" y=\"20\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um arquivo ou objeto</text><text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só quem tem a chave o abre</text><rect x=\"180.0\" y=\"72\" width=\"360\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma coluna</text><text x=\"360\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só consulta ou app com a chave</text><rect x=\"150.0\" y=\"124\" width=\"420\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os arquivos do banco (TDE)</text><text x=\"360\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quando o banco inicia</text><rect x=\"120.0\" y=\"176\" width=\"480\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o disco ou volume</text><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quando a máquina é desbloqueada</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decifrada mais tarde, confia em menos gente</text><polyline points=\"14,210 14,26\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#lay-ah-phosphor)\"></polyline></svg>", "caption": "Quanto mais alta a camada, mais tarde ela é decifrada, e em menos gente ela confia."}
```

**Cada camada é transparente para tudo o que está acima dela.** A cifragem de disco inteiro é
invisível para o sistema operacional depois de desbloqueada, e portanto para todo programa e todo
usuário da máquina em funcionamento. Essa transparência é o que a torna barata de implantar, e é
também o seu limite: um malware rodando num notebook desbloqueado lê os arquivos exatamente como o
dono lê. As próximas seções tratam das camadas em ordem, e a última trata da chave, que decide se
alguma delas vale alguma coisa.

## O que a cifragem em repouso nunca cobre

- **O sistema em funcionamento.** Dados na memória, em uso por um programa, estão decifrados.
  Protegê-los é trabalho do controle de acesso e das atualizações, não da cifragem do armazenamento.
- **Dados em trânsito.** Isso é o TLS e os protocolos das aulas 10 a 13.
- **Alguém com a chave.** Um atacante que rouba o disco e a frase-senha escrita num post-it ao lado
  tem as duas metades.

Para a Vereda, os riscos concretos são o notebook de um fisioterapeuta esquecido num táxi, o NAS da
clínica mandado para conserto e o backup noturno do banco copiado para um bucket na nuvem. Cada seção
diz quais deles ela cobre.
