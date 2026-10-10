---
title: Sondando a produção sem machucá-la
version: 1
---

Tudo o que uma sonda faz em produção, ela faz de verdade. **Cada reserva que ela faz é um assento
que um cliente não consegue comprar**, cada requisição é carga, e cada registro que ela escreve cai
nas mesmas tabelas de onde o negócio lê as suas vendas. Uma sonda rodando uma vez por minuto reserva
1.440 assentos por dia. A bilheteria tem vinte espetáculos de 300 assentos à venda; deixada sozinha,
a sonda esgota o primeiro espetáculo em poucas horas e depois reprova em toda verificação, tendo
causado a queda que ela relata.

## Marcando os dados de teste, e limpando depois

Três hábitos impedem que o tráfego sintético vire um problema próprio.

**Marque.** A sonda reserva como `synthetic-probe`, um cliente que nenhuma pessoa é, para que cada
linha que ela deixa possa ser achada e cada relatório possa deixá-la de fora. Algumas equipes mandam
um cabeçalho, como `X-Synthetic: 1`, e fazem a aplicação marcar a linha; a marca tem de chegar ao
banco de qualquer jeito, porque é de lá que o relatório de vendas lê.

**Dê a ela um lugar inofensivo para escrever.** Numa bilheteria real, a sonda reservaria um
espetáculo que nunca está à venda para o público, um evento de teste combinado com a operação, para
nunca pegar um assento que uma pessoa queria. A boxoffice não tem um espetáculo assim, que é por que
esta sonda reserva o primeiro espetáculo à venda, e por que ela precisa limpar depois.

**Limpe, num horário próprio.** Toda sonda que escreve precisa de uma remoção correspondente,
combinada com quem é dono dos dados, rodada com a mesma frequência da sonda ou logo depois. A
boxoffice não tem endpoint para cancelar uma reserva, então nesta máquina a limpeza é um comando
contra o banco, em `~/boxoffice`:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "SELECT show_id, seat, customer FROM bookings WHERE customer = 'synthetic-probe'"
981|190|synthetic-probe
981|6|synthetic-probe
981|30|synthetic-probe
981|175|synthetic-probe
981|236|synthetic-probe
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DELETE FROM bookings WHERE customer = 'synthetic-probe'; SELECT changes()"
5
```

Cinco reservas: uma da primeira execução, três do laço e uma da versão lenta, todas no espetáculo
981, todas marcadas, todas removidas num comando só. **Em produção você não digitaria isso num
prompt**: seria um job revisado, ou melhor, um endpoint que a aplicação oferece para o seu próprio
cliente de teste, para ninguém precisar de acesso de escrita à tabela de vendas para arrumar a casa
depois de um monitor.

## De mais de um lugar

Uma sonda na própria máquina do servidor prova que a aplicação responde. Ela não diz nada sobre o
DNS, o certificado, o balanceador de carga ou a rede entre os seus clientes e você, que é onde moram
muitas quedas reais. **Serviços sintéticos hospedados rodam a mesma verificação de várias regiões**
— São Paulo, Virgínia, Frankfurt, Singapura — por esse motivo, e o padrão das falhas diz onde está o
problema:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l23-regions\" aria-label=\"Dois painéis, cada um com três sondas, São Paulo, Virgínia e Frankfurt, mandando uma verificação a um serviço à direita. No painel da esquerda, as três falham: o problema é o serviço. No painel da direita, só a de Frankfurt falha e as outras duas passam: o serviço funciona, e o problema está no caminho a partir de Frankfurt.\"><defs><marker id=\"l23-regions-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-regions-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"185.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">todas falham: o serviço</text><rect x=\"250.0\" y=\"110.0\" width=\"100.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"20.0\" y=\"54.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">São Paulo</text><path d=\"M132.0 70.0 L246.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha</text><rect x=\"20.0\" y=\"124.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Virgínia</text><path d=\"M132.0 140.0 L246.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha</text><rect x=\"20.0\" y=\"194.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Frankfurt</text><path d=\"M132.0 210.0 L246.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha</text><text x=\"535.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma falha: o caminho dela</text><rect x=\"600.0\" y=\"110.0\" width=\"100.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"370.0\" y=\"54.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">São Paulo</text><path d=\"M482.0 70.0 L596.0 124.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-regions-nf-ah-phosphor)\"></path><text x=\"530.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">passa</text><rect x=\"370.0\" y=\"124.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Virgínia</text><path d=\"M482.0 140.0 L596.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-regions-nf-ah-phosphor)\"></path><text x=\"530.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">passa</text><rect x=\"370.0\" y=\"194.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Frankfurt</text><path d=\"M482.0 210.0 L596.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"530.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha</text></svg>", "caption": "A mesma verificação de três lugares. Quais falham diz onde procurar.", "same": ["Frankfurt", "São Paulo"]}
```

Todas as regiões falhando apontam para o serviço. Uma região falhando aponta para o caminho a partir
dela: a rede de um provedor de nuvem, um resolvedor de DNS, uma mudança de rota. Essa distinção
também é o motivo para uma falha isolada, de um lugar só, não acordar ninguém.

## O que uma verificação sintética não consegue ver

Uma sonda só percorre a jornada que alguém escreveu. Usuários reais pegam caminhos que ninguém
roteirizou: a busca com um acento, o celular num trem lento, a extensão do navegador que quebra a
página, o espetáculo que esgota enquanto trezentas pessoas estão na página dele ao mesmo tempo.
**Uma sonda verde quer dizer que o caminho roteirizado funciona, a partir do local da sonda, no ritmo
de um usuário só.** Não quer dizer que o sistema funciona para as pessoas que o usam, e a aula 24 é
sobre os defeitos que só aparecem quando elas o usam: uma taxa de erro que só sobe com tráfego real,
que é para o que servem as métricas de usuários reais e a razão de erro do próprio servidor.

Os dois tipos de monitoramento falham em direções opostas, e é por isso que andam juntos. Uma
verificação sintética soa o alarme às 04:00, quando ninguém foi afetado ainda; os dados de usuários
reais ficam em silêncio nessa hora, e são os únicos que percebem quando um décimo dos clientes de um
navegador não consegue pagar.
