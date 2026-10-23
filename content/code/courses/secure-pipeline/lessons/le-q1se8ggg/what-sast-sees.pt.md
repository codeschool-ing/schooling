---
title: O que a análise estática lê, e o que ela não consegue ler
version: 1
---

A análise estática costuma ser vendida como uma máquina que lê código e acha as vulnerabilidades
nele. O que ela faz de fato é mais estreito, e mais útil depois de entendido: **ela compara o código
com regras que alguém escreveu, sem executá-lo.** Cada regra descreve um formato que costuma ser um
erro, como um texto vindo de uma requisição chegando a uma consulta ao banco, e a ferramenta aponta
cada lugar onde o formato aparece. Ela acha aquilo para o que tem regra, no código que recebeu, e
nada mais.

Isso é tudo o que SAST, teste estático de segurança de aplicações, quer dizer. O resto desta aula são
duas ferramentas desse tipo no linkbox: o Bandit, com as regras que vêm com ele, e o Semgrep, com duas
regras escritas para este projeto. O estágio que roda as duas leva 3 segundos no linkbox na gravação
desta aula, bem dentro do orçamento de um push da aula 2.

### Origens, destinos e o caminho entre eles

A maioria das regras de segurança fala de um fluxo. Uma **origem** (source) é por onde entra um dado
que alguém de fora controla: os parâmetros de uma requisição, os cabeçalhos, um formulário, um
arquivo enviado. Um **destino** (sink) é uma chamada que faz algo perigoso com o que recebe: rodar
SQL, rodar um comando no shell, gravar um arquivo, renderizar HTML sem escapar. O defeito é um caminho
de uma origem até um destino sem nada no meio que torne o dado seguro.

O linkbox tem um caminho desses, na busca, e você o viu na aula 1:

```python
q = request.args.get("q", "")
rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l03-flow\" aria-label=\"Duas versões da busca do linkbox. Na aula 1 o texto da busca, vindo de request.args, é formatado dentro do texto SQL com uma f-string, e a string única chega a execute(), onde o SQLite lê tudo como SQL: código e dado num canal só. Na aula 3 o texto SQL é fixo, com uma interrogação onde vai o valor, e o texto da busca viaja separado, como parâmetro; o SQLite nunca o lê como SQL.\"><defs><marker id=\"sp-l03-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l03-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l03-flow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">aula 1: uma string só</text><text x=\"70\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">origem</text><rect x=\"15\" y=\"54\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request.args[\"q\"]</text><text x=\"90.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o usuário digitou</text><rect x=\"215\" y=\"54\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">f\"...LIKE '%{q}%'\"</text><text x=\"340.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">formatado dentro do SQL</text><text x=\"610\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">destino</text><rect x=\"515\" y=\"54\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execute(sql)</text><text x=\"610.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lido como SQL</text><path d=\"M165 82 L213 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-amber)\"></path><path d=\"M465 82 L513 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-amber)\"></path><line x1=\"15\" y1=\"140\" x2=\"705\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">aula 3: dois canais</text><rect x=\"215\" y=\"176\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">\"...LIKE ?\"</text><text x=\"340\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">texto SQL fixo</text><rect x=\"15\" y=\"236\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">request.args[\"q\"]</text><text x=\"90.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o usuário digitou</text><rect x=\"215\" y=\"244\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">(f\"%{q}%\",)</text><text x=\"340\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um parâmetro</text><rect x=\"515\" y=\"205\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">execute(sql, params)</text><text x=\"610.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lido como valor</text><path d=\"M165 264 L213 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-phosphor)\"></path><path d=\"M465 198 L490 198 L490 225 L513 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-paper-dim)\"></path><path d=\"M465 266 L490 266 L490 241 L513 241\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l03-flow-ah-phosphor)\"></path></svg>", "caption": "O defeito é um caminho de uma origem até um destino sem nada no meio que mantenha o dado fora do código."}
```

O texto digitado na caixa de busca vira parte do próprio SQL. Uma aspa nele fecha a string com que a
consulta queria comparar, e o que vem depois da aspa o SQLite lê como mais SQL. **Isso é injeção de
SQL, e o que a torna possível é código e dado viajarem numa string só.** A correção os mantém
separados: a consulta é escrita com um `?` onde vai o valor, e o valor é passado à parte, então o
banco nunca o lê como SQL. A aula 5 de `secure-code` trata do assunto inteiro; esta aula é sobre como
um pipeline acha o defeito e o mantém achado.

### Quanto do caminho uma ferramenta segue

As ferramentas diferem em quão longe seguem o dado, e a diferença decide o que elas podem deixar
passar.

| o que a ferramenta faz | o que ela vê | a busca do linkbox |
|---|---|---|
| compara uma linha ou uma chamada | uma consulta montada a partir de uma string, onde quer que esteja | achada, só pela f-string |
| segue valores dentro de uma função | que `q` veio de `request.args` | achada, e ela sabe por quê |
| segue valores entre funções e arquivos | uma origem num módulo chegando a um destino em outro | achada; necessário quando a consulta é montada num helper |

O Bandit trabalha no primeiro nível. Ele aponta uma consulta montada formatando uma string, seja o que
for que a string tenha, e isso o deixa rápido e simples. É também por isso que a mesma regra dispara
numa consulta montada a partir de uma constante, como a seção 04 mostra. O motor de código aberto do
Semgrep compara padrões, com algum fluxo dentro de uma função; o rastreamento mais fundo, entre
arquivos, fica em motores comerciais, incluindo o plano pago do próprio Semgrep, e não foi usado aqui.

### O que ela não consegue ver

A análise estática lê código. **Tudo o que só existe quando o programa roda está fora do alcance
dela**, e a lista é longa:

- **a configuração com que ele roda**: uma variável de ambiente que liga a depuração, uma
  configuração permissiva no servidor web na frente dele;
- **as respostas que ele envia**: um cabeçalho de segurança ausente é uma propriedade da resposta
  HTTP, que é a análise dinâmica da aula 4;
- **o código que você não escreveu**: uma falha no próprio Flask está numa dependência, que é a
  aula 5;
- **o design**: uma rota que nem deveria existir, ou uma que confia na parte errada, é código correto
  fazendo a coisa errada, e é para isso que serve a modelagem de ameaças.

Então uma análise estática limpa quer dizer uma coisa: **nenhuma das regras que rodaram achou o seu
formato no código que foi lido.** É uma afirmação forte sobre alguns erros conhecidos e nenhuma
afirmação sobre todo o resto. As próximas seções tornam isso concreto, começando pelo que o Bandit
aponta no código que você herdou.
