---
title: /etc: as configurações da máquina, em texto
version: 1
---

O **`/etc`** guarda a configuração da máquina inteira, e quase tudo nele é **texto puro**.

```
ana@server:~$ ls /etc | wc -l
122
ana@server:~$ cat /etc/hostname
server
ana@server:~$ cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 server
ana@server:~$ dpkg -S /etc/hosts /etc/crontab
dpkg-query: no path found matching pattern /etc/hosts
cron-daemon-common: /etc/crontab
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Dois jeitos de guardar configurações. No Linux, arquivos de texto em /etc, como /etc/hostname, /etc/hosts, /etc/systemd/journald.conf e os arquivos de /etc/apt/apt.conf.d; qualquer editor os abre, um programa por arquivo. No Windows, uma árvore chamada registro: HKEY_LOCAL_MACHINE, depois SOFTWARE, Microsoft, Windows NT e CurrentVersion, cada uma uma chave dentro da anterior; ele é aberto com regedit, reg ou PowerShell.\"><defs><marker id=\"md-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Linux: arquivos de texto em /etc</text><text x=\"380\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows: uma árvore, o registro</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/hostname</text><rect x=\"20\" y=\"70\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/hosts</text><rect x=\"20\" y=\"110\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/systemd/journald.conf</text><rect x=\"20\" y=\"150\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/apt/apt.conf.d/…</text><text x=\"20\" y=\"206\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abre em qualquer editor, um programa por arquivo</text><rect x=\"380\" y=\"30\" width=\"300\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HKEY_LOCAL_MACHINE</text><path d=\"M388 60 L388 77 L396 77\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"396\" y=\"64\" width=\"284\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"406\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SOFTWARE</text><path d=\"M404 94 L404 111 L412 111\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"412\" y=\"98\" width=\"268\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"422\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft</text><path d=\"M420 128 L420 145 L428 145\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"428\" y=\"132\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Windows NT</text><path d=\"M436 162 L436 179 L444 179\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"444\" y=\"166\" width=\"236\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CurrentVersion</text><text x=\"380\" y=\"206\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aberto com regedit, reg ou PowerShell</text></svg>", "caption": "Mesmo trabalho, dois formatos. Um arquivo de texto pode ser lido, comparado e copiado com as ferramentas da aula 12; uma chave do registro precisa de ferramentas que entendem o registro."}
```

- **122 itens** no `/etc` deste servidor mínimo, arquivos e pastas. Um desktop tem algumas centenas.
- O **`/etc/hostname`** é uma linha: o nome da máquina, o que aparece em todo prompt deste curso.
- O **`/etc/hosts`** liga nomes a endereços antes de qualquer servidor DNS ser consultado. O
  `127.0.1.1 server` é como a máquina acha a si mesma pelo nome. A seção 03 acrescenta uma linha a ele.
- O **`dpkg -S`** pergunta que pacote instalou um arquivo. O `/etc/crontab` pertence ao
  `cron-daemon-common`; o `/etc/hosts` não pertence a **pacote nenhum**, porque o instalador o escreveu
  para esta máquina. A diferença importa na atualização: os arquivos de configuração de um pacote são os
  que o apt sabe atualizar, e sobre os quais pergunta quando você os mudou.

Por ser texto, o `/etc` é legível com tudo o que a aula 12 ensinou: `cat`, `grep`, `less`, `diff`. É
também por isso que muitos administradores mantêm o `/etc` sob controle de versão, o assunto do curso de
git, para toda mudança ter data e motivo.
