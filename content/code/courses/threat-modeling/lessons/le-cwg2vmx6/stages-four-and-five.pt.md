---
title: Estágios 4 e 5, ameaças e fraquezas
version: 1
---

Os estágios do meio adotam a visão do atacante. O estágio 4 pergunta **quem ia querer prejudicar
este sistema, e como sistemas parecidos já foram prejudicados**. O estágio 5 pergunta **onde este
sistema em particular é fraco**, e junta as duas coisas.

### Estágio 4: análise de ameaças

O STRIDE produziu catorze ameaças a partir do desenho. O estágio 4 acrescenta o que o desenho não
tem como saber: o mundo lá fora. As entradas são **inteligência de ameaças** (relatos do que está
acontecendo com organizações parecidas), os próprios logs e incidentes do sistema, e a lista de
atores que poderiam agir.

Para uma rede de clínicas de fisioterapia no Brasil, o resumo da carla para o estágio 4 tinha três
linhas:

- **Serviços de saúde são alvo comum de extorsão.** Grupos criminosos cifram ou roubam dados de
  pacientes e pedem pagamento; quanto mais sensível o dado, mais forte a posição deles. Todo
  relatório setorial que a carla leu nos últimos dois anos punha a saúde perto do topo.
- **Credential stuffing atinge todo login de consumidor.** Senhas vazadas de outros sites são
  testadas automaticamente contra qualquer página de login que responda. O próprio log de login do
  portal mostra rajadas de logins falhos de endereços desconhecidos quase toda semana.
- **Ameaças internas existem, e em geral são descuido, e não má-fé.** Uma recepcionista olhando o
  prontuário de um vizinho é o caso clássico em dado de saúde, e não precisa de nada técnico.

Nenhuma dessas é ameaça nova na lista. O que o estágio 4 acrescenta é **quais das catorze têm alguém
tentando agora**: a T02 (credential stuffing) e a cadeia T03, T12, T09 (uma conta da equipe roubada
por phishing chegando aos prontuários) sobem. A T14 (um PDF preparado) é possível, mas ninguém nos
relatórios da carla estava fazendo isso com clínicas.

### Estágio 5: análise de fraquezas e vulnerabilidades

O estágio 5 liga cada ameaça a uma **fraqueza**: uma deficiência específica deste sistema que
deixaria a ameaça acontecer. Fraquezas recebem nome pelo **CWE**, a Common Weakness Enumeration da
MITRE, para que um achado do modelo, um achado de um scanner de código e uma linha num relatório
de pentest possam ser ligados pelo mesmo identificador. Vulnerabilidades conhecidas no software
que a Vereda roda, com nome pelo CVE, entram na mesma tabela quando existem.

| ameaça | fraqueza na Vereda | CWE |
|---|---|---|
| T01 | o handler do webhook não verifica a assinatura do gateway | CWE-345, verificação insuficiente da autenticidade dos dados |
| T03 | a equipe entra só com senha | CWE-308, autenticação de fator único |
| T05 | edições de anotações clínicas não são registradas | CWE-778, registro insuficiente |
| T07 | o download busca o exame pelo número no endereço, sem conferir o dono | CWE-639, contorno de autorização por chave controlada pelo usuário |
| T10 | uploads não têm limite de tamanho | CWE-770, alocação de recursos sem limites ou controle de taxa |
| T13 | o worker se conecta com a conta do dono | CWE-250, execução com privilégios desnecessários |

**A ligação é o ponto.** Quando um scanner rodado no curso `secure-pipeline` relatar CWE-639 na
rota de download, esta tabela diz qual ameaça ele confirma e qual objetivo de negócio ele põe em
risco. Sem o estágio 5, o achado do scanner e a ameaça do modelo são dois documentos que ninguém
liga.

Uma ameaça sem fraqueza achada não está fechada por isso. Significa que ninguém achou uma ainda, e
o estágio 5 a registra como "nenhuma fraqueza conhecida", com a data em que foi conferida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-cwe-join\" aria-label=\"O estágio 5 nomeia uma fraqueza para cada ameaça com um id CWE, para achados de fontes diferentes se juntarem. A T01, o webhook forjado, é CWE-345. A T07, PDFs de outros pacientes, é CWE-639. A T10, uploads sem limite, é CWE-770. A T13, o worker como dono, é CWE-250. Um achado de scanner ou um relatório de pentest que nomeie o mesmo CWE cai na mesma ameaça.\"><defs><marker id=\"l04-cwe-join-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T01</text><text x=\"76.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">webhook forjado</text><rect x=\"330.0\" y=\"20.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-345</text><path d=\"M280.0 39.0 L330.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"70.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T07</text><text x=\"76.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PDFs de outros pacientes</text><rect x=\"330.0\" y=\"70.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-639</text><path d=\"M280.0 89.0 L330.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"120.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T10</text><text x=\"76.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uploads sem limite</text><rect x=\"330.0\" y=\"120.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-770</text><path d=\"M280.0 139.0 L330.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"170.0\" width=\"260.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">T13</text><text x=\"76.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker como dono</text><rect x=\"330.0\" y=\"170.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CWE-250</text><path d=\"M280.0 189.0 L330.0 189.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"530.0\" y=\"60.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um achado de scanner</text><path d=\"M530.0 80.0 L450.0 39.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-cwe-join-tm-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"140.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um relatório de pentest</text><path d=\"M530.0 160.0 L450.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-cwe-join-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o id CWE é a junção, como um id opaco é em todo o resto</text></svg>", "caption": "Três fontes de achados, um vocabulário. Sem o id, a mesma fraqueza achada de três jeitos são três chamados."}
```
