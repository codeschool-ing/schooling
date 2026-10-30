---
title: O que é um conflito, e por que nada trava
version: 1
---

**Um conflito são duas escritas no mesmo registro, cada uma feita sem ver a outra.** A palavra
sugere um erro, uma faixa vermelha, uma sincronização que para. Nada disso acontece. As duas
escritas são válidas, as duas chegam ao servidor, e o servidor, que as vê uma depois da outra,
precisa decidir o que o registro diz agora. Qualquer que seja a regra, ele decide em silêncio.

Este é o caso que a aula acompanha. Na quarta-feira, 21 de outubro, Ana tem uma sessão de violão
no planner, `s3`: 20 minutos, não feita. Às 10:05, no trem e sem sinal, ela abre o planner no
celular e muda a sessão para 30 minutos. Às 10:20, em casa, onde o Wi-Fi está caído desde cedo,
ela marca a mesma sessão como feita no tablet. O tablet volta à rede às 10:40 e manda a cópia dele.
O celular pega sinal às 11:00 e manda a sua.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l13-timeline\" aria-label=\"Uma linha do tempo de uma manhã de quarta-feira em três faixas: celular, servidor, tablet. Às 10:05 o celular, offline num trem, muda a sessão s3 para 30 minutos. Às 10:20 o tablet, offline em casa, marca s3 como feita. Às 10:40 o tablet volta à rede e manda a cópia dele ao servidor. Às 11:00 o celular volta à rede e manda a sua. Nenhum aparelho viu a edição do outro antes de mandar a própria.\"><defs><marker id=\"l13-timeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">celular</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">servidor</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tablet</text><path d=\"M110 160 L700 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110 70 L600.0 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M600.0 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110 250 L450.0 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M450.0 250 L700 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">offline: no trem</text><text x=\"120\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">offline: Wi-Fi caído</text><text x=\"187.5\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:05</text><text x=\"300.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:20</text><text x=\"450.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:40</text><text x=\"600.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11:00</text><rect x=\"147.5\" y=\"82\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"187.5\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">minutes</text><text x=\"187.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">20 → 30</text><path d=\"M187.5 70 L187.5 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"252.0\" y=\"206\" width=\"96\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">done</text><text x=\"300.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">false → true</text><path d=\"M300.0 238 L300.0 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M450.0 250 L450.0 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-timeline-ah-phosphor)\"></path><text x=\"458.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">manda a cópia</text><path d=\"M600.0 70 L600.0 156\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-timeline-ah-phosphor)\"></path><text x=\"608.0\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">manda a cópia</text></svg>", "caption": "Duas edições com quinze minutos de distância, e ainda assim concorrentes: nenhum aparelho tinha visto a mudança do outro quando fez a sua.", "same": ["tablet"]}
```

Cada aparelho fez exatamente o que a aula 7 pede de um app offline-first: gravou localmente e disse
à Ana que a mudança estava salva. A caixa de saída da aula 8 entregou cada escrita uma vez, a chave
de idempotência da aula 10 garantiu que uma nova tentativa não a entregasse duas, e a sincronização
por delta da aula 11 vai levar a cada aparelho a linha do outro depois. **Nenhuma dessas peças
percebe que as duas escritas discordam.** Elas movem operações; não as comparam.

## Concorrentes, não simultâneas

As duas edições tiveram quinze minutos de distância, e ainda assim conflitam. O que as torna
concorrentes não é o relógio, mas o que cada aparelho sabia: o celular mudou os minutos sem ter
visto a marcação, e o tablet marcou sem ter visto os minutos. **Duas escritas conflitam quando
nenhuma foi feita por alguém que tinha visto a outra.** Uma escrita feita no tablet depois de ele
ter puxado a mudança do celular não é conflito nenhum, mesmo que chegue um segundo depois; é uma
edição comum da versão mais nova.

Essa definição é a dificuldade inteira. Um servidor que recebe uma linha não consegue saber, só pela
linha, se quem a mandou tinha visto a última escrita ou não. A aula 14 dá a ele a informação para
saber, com um número de versão e depois um relógio vetorial. Esta aula olha a regra com que a
maioria dos apps começa, porque ela não precisa de nada disso: guardar a última escrita e jogar a
outra fora.
