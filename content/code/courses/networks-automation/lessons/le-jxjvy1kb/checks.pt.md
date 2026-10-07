---
title: Verificações antes e depois de uma mudança
version: 2
---

Toda aula até aqui terminou com uma verificação: o diff antes de um commit, a comparação depois de
um push, o `assert` no playbook da aula 9. Esta aula as coloca em ordem e as torna automáticas.
**Uma mudança passa por cinco passos**, e o que mais importa em cada verificação é de que lado da
aplicação ela fica:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma mudança anda da esquerda para a direita por cinco passos. Descrever: os dados mudam. Validar: os dados são conferidos contra o modelo, sem nada renderizado. Testar offline: o pytest roda sobre os dados e as configurações renderizadas, sem tocar em roteador. Aplicar: as configurações são enviadas. Testar online: o pytest pergunta aos roteadores se a rede faz o que os dados dizem. Tudo antes de aplicar pode parar a mudança de graça; os testes online só acham um problema que os roteadores já têm, e a volta dali é um revert, desenhado como uma seta que retorna a descrever.\"><defs><marker id=\"cy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"60\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"72.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">descrever</text><text x=\"72.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data/*.yaml</text><rect x=\"152\" y=\"60\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"214.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">validar</text><text x=\"214.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">validate.py</text><path d=\"M136 95 L150 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><rect x=\"294\" y=\"60\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testar offline</text><text x=\"356.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_configs.py</text><path d=\"M278 95 L292 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><rect x=\"436\" y=\"60\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aplicar</text><text x=\"498.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">push.py</text><path d=\"M420 95 L434 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><rect x=\"578\" y=\"60\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testar online</text><text x=\"640.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_network.py</text><path d=\"M562 95 L576 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M8 40 L420 40 L420 50 L8 50 Z\" fill=\"var(--scan)\"></path><text x=\"214\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma falha aqui não custa nada</text><text x=\"570\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma falha aqui já está na rede</text><path d=\"M650 132 L650 190 L72 190 L72 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cy-ah)\"></path><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">revert: de volta aos últimos dados que passaram</text></svg>", "caption": "Toda verificação que pode rodar antes de a mudança ser aplicada é uma verificação que não custa nada quando falha."}
```

Tudo o que está à esquerda da aplicação roda sobre arquivos. Não precisa de roteador, leva uma
fração de segundo, e quando falha a rede nem percebeu. **Tudo o que está à direita roda contra a
rede** e só pode relatar um problema que os roteadores já têm; o valor disso é achar os problemas
que nenhum arquivo consegue mostrar, e achá-los em segundos em vez de quando alguém liga.

São dois tipos de teste, então. **Testes offline** leem os dados e as configurações renderizadas:
todo valor está bem formado, algum endereço é usado duas vezes, toda interface OSPF recebe sua
linha network? **Testes online** perguntam à rede se ela faz o que os dados dizem: as adjacências
estão de pé, toda filial é alcançável? O vocabulário varia, pré-checks e pós-checks, testes
unitários e de integração, mas a linha entre eles é sempre a mesma: se o teste precisa da rede.

O projeto é o da aula 10, num repositório Git, com os dados em YAML. Um pipeline, que a aula 14
constrói, roda quando arquivos mudam, e arquivos são o que esta aula testa. Com o NetBox como
fonte, os mesmos testes rodam sobre o que o `render_nb.py` produz.

Ele começa dos arquivos da aula 10, num `~/net` novo no `ctl`. O `~/net` da aula 11 era outro
projeto, o dos backups, então ele sai do caminho primeiro; os dados, o template e o `push.py` são
copiados do `~/tpl` da aula 10:

```
ana@ctl:~$ mv net net-lesson11 2>/dev/null; mkdir -p net/templates && cp -r tpl/data tpl/push.py net/ && cp tpl/templates/frr.j2 net/templates/
```

As seções abaixo acrescentam o resto: um modelo e um script que confere os dados contra ele, um
`render.py` que os testes conseguem importar, e os próprios testes.
