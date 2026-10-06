---
title: Os quatro tratamentos
version: 1
---

Depois que um risco é ordenado, alguma coisa precisa ser decidida sobre ele. Existem exatamente
quatro opções, e toda decisão de segurança que você vai ver é uma delas, ou uma mistura:

```schooling-figure
{"svg": "<svg id=\"sf-treatments\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os quatro tratamentos de um risco. Mitigar: pôr um controle que baixe probabilidade ou impacto. Transferir: passar consequências a outro por contrato, como um seguro; a responsabilidade fica. Evitar: parar a atividade que cria o risco. Aceitar: conviver com ele, por escrito, assinado e com data.\"><defs><marker id=\"sf-treatments-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"270\" y=\"14\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">um risco ordenado</text><path d=\"M360 48 L100 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"20\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mitigar</text><rect x=\"20\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pôr um controle</text><text x=\"100\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">baixar probabilidade ou impacto</text><path d=\"M360 48 L275 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"195\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">transferir</text><rect x=\"195\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seguro, um contrato</text><text x=\"275\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a responsabilidade fica</text><path d=\"M360 48 L450 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"370\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">evitar</text><rect x=\"370\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parar a atividade</text><text x=\"450\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o risco vai a zero</text><path d=\"M360 48 L625 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"545\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aceitar</text><rect x=\"545\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conviver com ele</text><text x=\"625\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escrito, assinado, datado</text></svg>", "caption": "Quatro respostas para qualquer risco. Cada uma termina com alguém aceitando o que sobra."}
```

**Mitigar** (ou reduzir, ou modificar) é pôr um controle que baixe a probabilidade, o impacto ou os
dois. Trocar a senha padrão do portal e acrescentar MFA mitiga o R1 eliminando a vulnerabilidade. Um
backup offline mitiga o R2 encolhendo o impacto. Quase todo este curso é sobre mitigação, e por isso
é fácil esquecer que ela é só uma de quatro.

**Transferir** (ou compartilhar) é passar parte das consequências para outro, em geral por contrato.
Um seguro cibernético paga a limpeza depois de um incidente. Levar os pagamentos da loja para um
provedor de pagamento faz os números de cartão nunca tocarem o servidor da loja, e o provedor
carrega essa parte do risco. **O que não se transfere é a responsabilidade.** Se os dados dos
clientes vazam de um fornecedor que a loja escolheu, os clientes, a imprensa e a ANPD continuam
olhando para a loja. O seguro paga dinheiro; não desfaz o dano.

**Evitar** (ou eliminar) é parar a atividade que cria o risco. A loja guardava cópias dos documentos
de identidade dos clientes "por via das dúvidas"; apagá-las e não pedi-las mais evita o risco
inteiro de vazá-las. Evitar é pouco usado porque parece abrir mão de algo, e é o único tratamento
que leva um risco a zero.

**Aceitar** (ou reter) é decidir, sabendo o que faz, conviver com o risco como ele está. A loja
aceita o R5: enchente é rara, a loja fica no terceiro andar, e mudar custaria muito mais que a perda
esperada. **Aceitar é uma decisão legítima, não uma falta de decisão**, desde que três coisas sejam
verdade: está escrito, foi assinado por alguém com autoridade para aceitar aquele tanto de risco, e
tem uma data para ser revisto.

| risco | tratamento | o que se faz |
|---|---|---|
| R1 senha padrão do portal | mitigar | senha única, MFA, portal fora da internet |
| R2 ransomware | mitigar e transferir | backup offline; seguro para a limpeza |
| R3 notebook perdido | mitigar | disco cifrado, para que um notebook perdido seja só um aparelho perdido |
| R4 atualização que falhou | mitigar | testar as atualizações numa cópia antes |
| R5 enchente | aceitar | assinado pelos sócios, revisto todo ano |

A diferença entre aceitar e negligenciar é o papel. Um risco que ninguém olhou não foi aceito; foi
ignorado, e quando ele acontece ninguém consegue dizer se foi uma aposta razoável ou um descuido. A
aula 13 volta a isso, porque é exatamente essa a pergunta que os auditores fazem.
