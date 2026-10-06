---
title: Isolamento
version: 1
---

O menor privilégio diz o que uma conta pode tocar. O **isolamento** vai um passo além: põe um programa
num lugar de onde ele nem enxerga o que não pode tocar. Um programa que não vê o arquivo de salários
não pode ser enganado para lê-lo, e um que não vê a rede não consegue mandar nada por ela.

O isolamento vem em forças, e cada degrau acima custa mais e contém mais:

```schooling-figure
{"svg": "<svg id=\"sf-isolation\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Seis níveis de isolamento como uma escada que sobe, do mais fraco ao mais forte: contas separadas, sandbox, contêiner, máquina virtual, hardware separado, air gap. Uma seta embaixo diz que cada degrau contém mais e custa mais.\"><defs><marker id=\"sf-isolation-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"130\" width=\"105\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contas</text><text x=\"72\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">separadas</text><rect x=\"135\" y=\"108\" width=\"105\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"187\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sandbox</text><rect x=\"250\" y=\"86\" width=\"105\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"302\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contêiner</text><rect x=\"365\" y=\"64\" width=\"105\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">máquina</text><text x=\"417\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">virtual</text><rect x=\"480\" y=\"42\" width=\"105\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hardware</text><text x=\"532\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">separado</text><rect x=\"595\" y=\"20\" width=\"105\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"647\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">air gap</text><path d=\"M20 200 L700 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isolation-ah-paper-dim)\"></path><text x=\"20\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais fraco, mais barato</text><text x=\"700\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais forte, mais caro</text></svg>", "caption": "Cada degrau acima esconde mais do sistema do programa, e custa mais para manter.", "same": ["sandbox", "air gap"]}
```

| nível | o que separa os dois lados | um exemplo |
|---|---|---|
| **contas separadas** | as permissões do sistema operacional | o portal como `shop`, o bruno como `bruno`, na mesma máquina |
| **sandbox** | o programa é iniciado com quase todo o sistema escondido dele | uma aba do navegador que não lê seus arquivos |
| **contêiner** | a própria visão de arquivos, processos e rede, compartilhando o kernel do host | o portal num contêiner que só vê a própria pasta |
| **máquina virtual** | o próprio sistema operacional e kernel, sobre hardware virtual | o portal num servidor virtual só dele |
| **hardware separado** | máquinas físicas diferentes | o banco num servidor só dele |
| **air gap** | nenhuma conexão de rede | um disco de backup offline na gaveta |

Duas lições se escondem nessa tabela.

**Cada nível falha de um jeito.** Um contêiner compartilha o kernel com o host, então uma falha no kernel
pode deixar um programa escapar dele; uma máquina virtual tem o próprio kernel, então a mesma falha fica
lá dentro. É por isso que a escolha é sobre o que o programa faria se desse errado, e não só sobre
conveniência. `virtualization` e `docker` tratam direito das duas linhas do meio; aqui o ponto é que elas
são degraus da mesma escada.

**O isolamento já estava neste curso.** O próprio laboratório é isolamento: cada máquina é um namespace
de rede separado, então o `www` não vê o tráfego do escritório a não ser pelo firewall. A DMZ da aula 5 é
isolamento na escala de uma rede. O backup offline que poupou à loja R$ 2.100 por ano na aula 3 é um air
gap, o nível mais forte, escolhido exatamente porque um ransomware no servidor não alcança o que o
servidor não enxerga.

### Quando isolar

Quanto mais exposto e menos confiável é um programa, mais isolamento ele merece. Um programa que lê
entrada de estranhos, como as páginas públicas da loja, um arquivo enviado por um cliente ou um anexo de
e-mail, fica alto nas duas contas. Abrir um anexo desconhecido numa sandbox, ou processar envios num
contêiner que não guarda mais nada, faz com que o pior que ele consiga seja estragar a sandbox. A aula 12
de `defense-hardening` mostra essa prática para arquivos suspeitos.
