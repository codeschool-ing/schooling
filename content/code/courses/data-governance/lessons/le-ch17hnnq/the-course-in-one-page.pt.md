---
title: O curso em uma página
version: 1
---

Onze aulas construíram do zero a governança de uma empresa. Vale vê-la num lugar só, porque cada peça
se apoia nas outras:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-map\" aria-label=\"O curso em camadas. Embaixo, o acesso: quem pode conectar e quem pode ler o quê, aulas 1 e 2. Acima, a proteção: cifragem, chaves e pseudônimos, aulas 3 a 5. Acima disso, o conhecimento: o que se guarda e quão sensível é, aula 6. Depois a lei, aulas 7 e 8. Depois a governança: donos, qualidade, linhagem, retenção e auditoria, aulas 9 e 10. No topo, os contratos com os outros, aula 11. Toda camada guarda as suas decisões como dado e as verifica.\"><rect x=\"110.0\" y=\"18.0\" width=\"340.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contratos com os outros</text><text x=\"560.0\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aula 11</text><rect x=\"94.0\" y=\"62.0\" width=\"372.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">donos, qualidade, linhagem, retenção, auditoria</text><text x=\"560.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aulas 9 e 10</text><rect x=\"78.0\" y=\"106.0\" width=\"404.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a lei: LGPD, GDPR, AI Act</text><text x=\"560.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aulas 7 e 8</text><rect x=\"62.0\" y=\"150.0\" width=\"436.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que guardamos, e quão sensível</text><text x=\"560.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aula 6</text><rect x=\"46.0\" y=\"194.0\" width=\"468.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cifragem, chaves, pseudônimos</text><text x=\"560.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aulas 3 a 5</text><rect x=\"30.0\" y=\"238.0\" width=\"500.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">quem conecta, quem lê</text><text x=\"560.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aulas 1 e 2</text></svg>", "caption": "Cada camada se apoia nas de baixo."}
```

| aula | o que a Ipê tem agora | a pergunta que responde |
|---|---|---|
| 1 | papéis por pessoa, o `pg_hba.conf` lido de cima para baixo, ninguém por padrão | quem pode conectar, e como quem? |
| 2 | papéis por função, segurança por linha e por coluna | quem pode ler o quê? |
| 3 | TLS conferido, cifragem em repouso, e os limites dela | quem poderia ler no caminho, ou no disco? |
| 4 | chaves no OpenBao, cifragem de envelope, um audit device | quem guarda as chaves, e quem as usou? |
| 5 | tokens, máscaras, um hash com chave, k-anonimato | o que dá para usar sem a identidade? |
| 6 | `gov.column_class`, minimização, dados de teste sintéticos | o que guardamos, e quão sensível é? |
| 7 | eventos de consentimento, o registro de pedidos, a exportação, o RIPD | o que a lei pede, e conseguimos provar? |
| 8 | dois relógios de violação, um inventário de IA | o que muda numa fronteira, e com IA? |
| 9 | donos, regras de qualidade que rodam, um dicionário, linhagem | quem responde, e o dado presta? |
| 10 | um cronograma de retenção, um expurgo, bloqueios, uma trilha só de inserção | por quanto tempo, e quem fez o quê? |
| 11 | um contrato, conferido | o que prometemos a quem? |

## O que as peças têm em comum

Toda peça é **uma decisão guardada onde uma máquina consegue lê-la**: um papel, uma policy, uma linha
numa tabela de governança, uma restrição, um gatilho, um contrato num repositório. E quase toda peça vem
com **uma verificação que falha** quando a realidade e a decisão discordam: as colunas sem classe, as
tabelas sem dono, as regras de qualidade, as linhas vencidas, o contrato.

Esse é o método inteiro. Leis mudam — as datas da aula 8 vão mudar —, e também mudam ferramentas,
empresas e pessoas. Um time que guarda as suas decisões como dado, e as confere a cada mudança, responde
a uma lei nova com uma consulta e uma migração. Um time que as guarda na cabeça das pessoas responde com
um projeto.
