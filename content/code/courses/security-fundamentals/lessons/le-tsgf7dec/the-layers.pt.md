---
title: As camadas, do prédio aos dados
version: 1
---

Um jeito útil de listar as camadas é de fora para dentro: o que uma ameaça precisa atravessar, em
ordem, para chegar aos dados. Cada camada tem seus controles e seus furos típicos.

```schooling-figure
{"svg": "<svg id=\"sf-layers\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Defesa em profundidade como camadas aninhadas. De fora para dentro: política e pessoas, física, perímetro, rede interna, host, aplicação e, no centro, os dados. Uma ameaça de fora tem de atravessar cada anel para chegar aos dados.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"272\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"25.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">política e pessoas</text><rect x=\"64\" y=\"34\" width=\"592\" height=\"232\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">física</text><rect x=\"108\" y=\"54\" width=\"504\" height=\"192\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"118\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">perímetro</text><rect x=\"152\" y=\"74\" width=\"416\" height=\"152\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rede interna</text><rect x=\"196\" y=\"94\" width=\"328\" height=\"112\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host</text><rect x=\"240\" y=\"114\" width=\"240\" height=\"72\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplicação</text><rect x=\"284\" y=\"134\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">dados</text></svg>", "caption": "Sete camadas entre o lado de fora e os dados. Cada uma tem seus controles e seus furos.", "same": ["host"]}
```

| camada | o que protege | controles na livraria | um furo típico |
|---|---|---|---|
| **política e pessoas** | tudo, decidindo o que é permitido | uma política de uso aceitável, treinamento, um processo para quem sai | uma regra que ninguém comunicou |
| **física** | o próprio hardware | escritório trancado, rack trancado, livro de visitas | uma porta escorada aberta |
| **perímetro** | a fronteira com a internet | um firewall na borda (aula 5) | uma regra que libera demais |
| **rede interna** | o tráfego entre as máquinas da própria loja | segmentos que o escritório não atravessa (aula 5) | uma rede plana onde tudo alcança tudo |
| **host** | cada computador | patches, disco cifrado, poucos programas instalados | uma atualização faltando |
| **aplicação** | cada programa que atende pessoas | login, verificação de permissão (aula 8), verificação de entrada | uma página que esqueceu de verificar |
| **dados** | a própria informação | criptografia, backups (aula 12), permissões de arquivo | uma cópia esquecida em algum lugar sem proteção |

Duas linhas são fáceis de esquecer, e cada uma é uma aula em si.

**Política e pessoas ficam em volta de todo o resto.** Uma regra de firewall existe porque alguém
decidiu que tráfego é permitido; sem a decisão, a regra é um chute. Treinamento é um controle como
outro qualquer, com as mesmas forças e furos: diminui a chance de alguém clicar no boleto falso, e
nunca leva essa chance a zero, e é por isso que as camadas de dentro continuam importando.

**Dados são a última camada, e a que viaja.** Todas as outras camadas protegem um lugar. Dados saem
dos lugares: são copiados para um notebook, anexados num e-mail, postos num backup. Controles sobre
o próprio dado, como criptografia e permissões que vão junto com o arquivo, são os únicos que ainda
o protegem quando ele está onde as outras camadas não chegam.

A ordem também diz algo sobre custo. Controles perto de fora são compartilhados: um firewall protege
todas as máquinas atrás dele. Controles perto do centro são específicos: cada aplicação precisa das
próprias verificações de permissão, escritas e testadas por quem a escreveu. Um bom projeto usa os
dois, porque as camadas de fora são baratas por ativo e grosseiras, e as de dentro são caras e
precisas.
