---
title: Funções de aptidão
version: 1
---

Um registro explica uma decisão; não a impõe. O ADR 4 diz nada de `SELECT *` em `app/`, e um ano depois
uma mudança apressada acrescenta um, e nada percebe até uma página ficar lenta. A defesa mais forte de uma
decisão é fazer o build conferi-la.

Neal Ford, Rebecca Parsons e Patrick Kua chamaram essas conferências de **funções de aptidão** (*fitness
functions*), em *Building Evolutionary Architectures*: um teste automático de uma propriedade da
arquitetura, rodado com a mesma frequência com que o código muda. A do laboratório é o `check.sh`. Rode-o
contra o código do catálogo, que foi escrito antes do ADR 4:

```
ana@vm:~/lab/adr$ bash check.sh; echo "exit status $?"
app/catalogue.py:2:    return db.execute("SELECT * FROM products ORDER BY id").fetchall()
ADR 4: name the columns; SELECT * is not allowed under app/
exit status 1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma decisão, o ADR 4, nada de SELECT asterisco no código da aplicação, vira uma conferência, check.sh, que roda no CI a cada mudança. Uma mudança que acrescenta SELECT asterisco em app falha na conferência e não pode ser integrada; uma que nomeia as colunas passa.\"><defs><marker id=\"l20-fitness-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-fitness-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ADR 4</text><rect x=\"270\" y=\"80\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">check.sh no CI</text><path d=\"M192 105 L268 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-phosphor)\"></path><text x=\"230\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vira</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">SELECT * em app/</text><text x=\"600\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha: não integra</text><rect x=\"510\" y=\"130\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">colunas nomeadas</text><text x=\"600\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">passa</text><path d=\"M432 95 L508 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-amber)\"></path><path d=\"M432 115 L508 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-fitness-ah-phosphor)\"></path></svg>", "caption": "Uma função de aptidão torna uma decisão executável: o build a defende em toda mudança, muito depois de as pessoas que a tomaram terem seguido em frente."}
```

Ele achou a linha e falhou, com uma mensagem que nomeia o registro, para a pessoa cuja mudança ele parou
poder ler o porquê. Conserte a consulta do jeito que o ADR 4 pede, e rode de novo:

```
ana@vm:~/lab/adr$ sed -i 's/SELECT \* FROM products/SELECT id, name, cents FROM products/' app/catalogue.py
ana@vm:~/lab/adr$ bash check.sh; echo "exit status $?"
ADR 4: ok
exit status 0
```

Num repositório de verdade o `check.sh` roda no CI a cada pull request, e uma mudança que quebra o ADR 4
não pode ser integrada. Funções de aptidão vêm em muitos tamanhos:

| decisão | a conferência |
| --- | --- |
| módulos não mexem nas tabelas uns dos outros | um teste que lê os imports ou o SQL e falha num proibido (ArchUnit em Java, `import-linter` em Python) |
| a página do checkout responde em menos de 300 ms | um teste de desempenho no pipeline com um limite |
| todo serviço expõe `/health` | um teste contra a implantação de cada serviço |
| nenhum serviço chama outro de forma síncrona a partir de um consumidor de mensagens | uma conferência estática no código do consumidor |

Nem toda decisão pode ser conferida, e uma conferência que dá alarme falso acaba desligada. Mas cada uma
que pode ser conferida para de depender de alguém lembrar do registro, que é a única coisa que um registro
não consegue garantir.
