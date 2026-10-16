---
title: A linha entre o administrador e o desenvolvedor
version: 1
---

A maioria das discussões neste trabalho acontece numa linha: onde termina a responsabilidade do
desenvolvedor e começa a do administrador. A linha não fica onde as pessoas costumam traçá-la — "o
desenvolvedor escreve código, o DBA cuida do banco" —, porque a coisa mais importante do banco, o
esquema, é escrita pelos dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 286\" role=\"img\" aria-label=\"Seis camadas da aplicação até a máquina. A aplicação e suas consultas são do desenvolvedor. O esquema é compartilhado. Papéis e grants, a configuração, memória e manutenção do servidor, e upgrades, logs e capacidade são do DBA. A máquina embaixo é compartilhada com quem cuida do sistema operacional.\"><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quem responde por isso</text><rect x=\"10\" y=\"30\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a aplicação e suas consultas</text><rect x=\"470\" y=\"30\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">desenvolvedor</text><rect x=\"10\" y=\"72\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o esquema: tabelas, chaves, índices</text><rect x=\"470\" y=\"72\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">compartilhado</text><rect x=\"10\" y=\"114\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">papéis, grants e privilégios</text><rect x=\"470\" y=\"114\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"156\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o servidor: configuração, memória, manutenção</text><rect x=\"470\" y=\"156\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"198\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">upgrades, logs e capacidade</text><rect x=\"470\" y=\"198\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"240\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a máquina: disco, sistema de arquivos, SO</text><rect x=\"470\" y=\"240\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">compartilhado</text></svg>", "caption": "A linha passa pelo esquema. Acima dela decide o desenvolvedor; abaixo, o DBA; o esquema é onde os dois precisam concordar.", "same": ["DBA"]}
```

**Acima da linha, decide o desenvolvedor.** O que a aplicação pergunta, em que ordem, dentro de quais
transações, e como ela reage quando o banco diz não. Uma consulta que lê um milhão de linhas para
mostrar vinte é do desenvolvedor consertar, e um administrador que acrescenta um índice em silêncio
para escondê-la não consertou nada: a próxima consulta vai fazer o mesmo.

**Abaixo da linha, decide o administrador.** Como o servidor é configurado, quanta memória usa e para
quê, com que frequência recebe manutenção, qual versão roda, o que registra no log, quem pode entrar
e de onde, e se o disco vai durar. Um desenvolvedor que muda o `shared_buffers` do servidor de
produção porque um post de blog mandou cruzou a linha na outra direção.

**O esquema é compartilhado, e é de propósito.** O desenvolvedor sabe o que os dados significam; o
administrador sabe quanto uma mudança vai custar numa tabela de duzentos milhões de linhas.
Acrescentar uma coluna é uma linha de código para um e uma trava na tabela mais movimentada da
empresa para o outro, e a lição 22 é sobre fazer isso de modo que os dois tenham razão.

## Como isso fica numa semana comum

| situação | quem age | quem é avisado |
|---|---|---|
| uma funcionalidade nova precisa de uma tabela | o desenvolvedor escreve a migração | o administrador a revisa antes de rodar em produção |
| uma consulta ficou lenta depois de um release | o desenvolvedor, com os números do administrador | os dois |
| o disco está 80% cheio | o administrador | a equipe, com a data em que chega a 100% |
| um serviço novo precisa ler duas tabelas | o administrador cria o papel e os grants | o desenvolvedor, com o nome do papel |
| uma versão menor corrige uma falha de segurança | o administrador a agenda | todos, com a hora do reinício |
| o autovacuum não dá conta de uma tabela | o administrador o ajusta | o desenvolvedor, se a causa é o jeito como a tabela é escrita |

O padrão da última coluna é o ponto. **Nenhum dos lados mexe no banco sem avisar o outro**, porque
as decisões de cada um caem na metade do outro: um reinício sem aviso quebra uma aplicação que não
reconecta, e uma migração sem aviso toma uma trava que ninguém planejou.
