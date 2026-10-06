---
title: A regra 3-2-1
version: 1
---

Quantas cópias, e onde? A regra prática que sobreviveu a várias gerações de tecnologia é a **3-2-1**:

```schooling-figure
{"svg": "<svg id=\"sf-three-two-one\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A regra 3-2-1 na livraria. Três cópias: os dados vivos no servidor db, um backup noturno num disco no escritório e uma cópia semanal fora do local. Dois tipos de armazenamento: o disco do servidor e uma cópia externa ou na nuvem. Uma cópia longe da loja.\"><defs><marker id=\"sf-three-two-one-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"440\" height=\"140\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o escritório da loja</text><rect x=\"40\" y=\"60\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · dados vivos</text><text x=\"130\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no db</text><rect x=\"260\" y=\"60\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · backup noturno</text><text x=\"350\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">disco no escritório</text><rect x=\"510\" y=\"60\" width=\"190\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · cópia semanal</text><text x=\"605\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fora do local, cifrada</text><path d=\"M220 95 L260 95\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-two-one-ah-wire)\"></path><path d=\"M440 95 L510 95\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-two-one-ah-wire)\"></path><text x=\"20\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">3 cópias</text><text x=\"250\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">2 tipos de armazenamento</text><text x=\"510\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1 fora do local</text><text x=\"20\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e hoje, uma delas offline ou imutável</text></svg>", "caption": "Três cópias, dois tipos de armazenamento, uma longe do prédio."}
```

- **3** cópias dos dados: o original e dois backups;
- em **2** tipos diferentes de armazenamento, para que um tipo de falha não leve os dois: um disco e um
  serviço de nuvem, um servidor e uma fita;
- **1** delas **fora do local**, num lugar que um incêndio, uma enchente ou um furto na loja não
  alcançam.

Na livraria: os dados vivos no `db`; um backup noturno no disco de backup do escritório; e uma cópia
semanal levada para casa por um dos sócios num disco externo cifrado, ou mandada para um serviço de
armazenamento na nuvem. Três cópias, dois meios, uma longe.

### A cópia que o ransomware não alcança

A regra original é anterior ao ransomware, e o ransomware mudou uma coisa: um atacante que controla o
servidor consegue apagar ou cifrar todo backup em que o servidor consegue escrever. Um disco de backup
ligado o tempo todo no servidor, ou um bucket na nuvem que as credenciais do servidor conseguem apagar,
cai junto com o servidor. Então a versão moderna acrescenta uma exigência, muitas vezes escrita
**3-2-1-1-0**:

| acréscimo | o que quer dizer |
|---|---|
| **1** cópia offline ou imutável | desconectada (um disco na gaveta) ou guardada onde nada, nem um administrador, consegue mudá-la até uma data passar |
| **0** erros | todo backup é verificado e testado na restauração, e a contagem de falhas é zero |

A cópia offline é o controle do R2 da aula 3, o que poupou à loja R$ 2.100 por ano, e o air gap da aula
6: o ransomware não cifra o que não alcança.

### Backups também precisam de proteção

Um backup guarda a mesma lista de clientes que o banco, e a aula 1 avisou que cópias multiplicam os
lugares de onde os dados podem vazar. Então backups são **cifrados**, e a chave fica em outro lugar que
não o backup, e em outro lugar que não o servidor que ele protege. Perdeu a chave, os backups não servem
para nada; guardou-a no servidor, o ransomware a leva junto. A tensão da aula 1 entre confidencialidade
e disponibilidade mora exatamente aqui, e a resposta é uma chave com o próprio backup, guardada por uma
pessoa.
