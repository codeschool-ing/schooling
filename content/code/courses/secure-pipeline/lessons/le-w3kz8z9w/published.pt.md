---
title: Um segredo no Git é um segredo publicado
version: 1
---

O linkbox carrega o token de administração em `settings.py` desde o dia em que foi entregue, e a
aula 3 deixou para esta aula o alerta de baixa severidade do Bandit sobre ele. O jeito comum de
pensar nisso é que o repositório é privado, então só o time vê o token. Essa imagem está errada de
duas maneiras, e as duas decidem qual tem de ser a resposta.

**Um commit não é uma mudança num arquivo. É uma fotografia de todos os arquivos, e todo clone copia
todas as fotografias.** Apagar a linha amanhã acrescenta uma sexta fotografia sem o token; as cinco
anteriores continuam com ele, em toda cópia do repositório que existe.

### Conte as cópias

Pergunte ao seu próprio repositório quais commits guardam o token. `git rev-list --all` lista todos
os commits, e `git grep` procura nos arquivos de cada um:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ git rev-list --all | wc -l
5
ana@vm:~/linkbox$ git grep -l lbx_7Rq2 $(git rev-list --all)
19d07382f253145808a4b99c02849049c0355c42:settings.py
d1186dff5922c15623d2ade11437f5298686abca:settings.py
3afa289dec6ea8fa854b60518eecb2feb97971cb:settings.py
ed9bbb4ba57f364006501e459dbcab550bea50c8:settings.py
3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py
ana@vm:~/linkbox$ git -C ~/ci/linkbox.git grep -n lbx_7Rq2 main -- settings.py
main:settings.py:4:ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
```

**Os cinco commits o carregam**, não só o primeiro, porque cada fotografia depois da primeira
manteve o arquivo como estava. O último comando pergunta ao servidor de CI, que guarda a própria
cópia do histórico inteiro: a aula 1 fez push para ele, e cada push desde então acrescentou algo.
São dois repositórios num laptop só, e cada execução do pipeline das aulas anteriores clonou um
terceiro em `~/ci/runs/N/src`.

Num time, a conta cresce sem que ninguém decida. Todo desenvolvedor tem um clone, e também todo
runner de CI que já construiu o projeto. Um fork numa plataforma hospedada é outra cópia completa,
feita por outra pessoa e guardada na conta dela. Os backups do servidor copiam tudo de novo. Nenhuma
dessas cópias fica sabendo quando você apaga uma linha, e nenhuma diminui quando alguém sai do time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l06-copies\" aria-label=\"Onde o histórico do linkbox, e o token com ele, é copiado. Na sua máquina: ~/linkbox, onde cinco commits o contêm; o servidor de CI ~/ci/linkbox.git, que recebeu todo push; e ~/ci/runs/N/src, um clone completo por execução do pipeline. Num time, também: o clone de um colega, um fork numa plataforma hospedada e um backup do servidor, cada um com o histórico inteiro.\"><defs><marker id=\"sp-l06-copies-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l06-copies-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l06-copies-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"118\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua máquina</text><rect x=\"25\" y=\"50\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/linkbox</text><text x=\"115.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 commits o contêm</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/linkbox.git</text><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 commits o contêm</text><rect x=\"515\" y=\"50\" width=\"185\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"607.5\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/ci/runs/N/src</text><text x=\"607.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um clone completo por execução</text><path d=\"M205 78 L263 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-copies-ah-phosphor)\"></path><text x=\"234\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">git push</text><path d=\"M455 78 L513 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-copies-ah-paper-dim)\"></path><text x=\"484\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">clone</text><rect x=\"10\" y=\"150\" width=\"700\" height=\"128\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">num time, também</text><rect x=\"25\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o clone de um colega</text><text x=\"120.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o histórico inteiro</text><rect x=\"265\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um fork</text><text x=\"360.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o histórico inteiro</text><rect x=\"505\" y=\"200\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um backup</text><text x=\"600.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o histórico inteiro</text><path d=\"M360 106 L360 135 L120 135 L120 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path><path d=\"M360 135 L360 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path><path d=\"M360 135 L600 135 L600 198\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l06-copies-ah-amber)\"></path></svg>", "caption": "Cada caixa guarda o histórico inteiro, e o token com ele. Um commit que apaga a linha não muda nada do que qualquer uma delas já guarda."}
```

### Privado é uma lista de pessoas, e a lista muda

Um repositório privado pode ser lido por quem está na lista de acesso hoje, e por todo mundo que
esteve nela em qualquer dia desde que o segredo entrou num commit. O prestador de serviço que saiu
em março ainda tem o clone que fez em fevereiro. Um repositório que vira público um ano depois
publica todos os commits que tem, e tornar um repositório público é uma configuração que alguém
muda em um minuto. O relatório anual de investigação de vazamentos da Verizon põe credenciais
roubadas no topo, ou perto do topo, da lista de portas de entrada há anos, e o vazamento raramente
é alguém invadindo para ler um repositório: é um repositório lido por alguém que tinha permissão,
uma vez.

Então a regra com que esta aula trabalha é rígida. **Um segredo que entrou num commit foi publicado
para todo mundo que algum dia pôde ler o repositório**, e a resposta é a que você daria a um
segredo publicado: primeiro ele para de funcionar, e a limpeza vem depois.

### O que conta como segredo

Qualquer coisa que dá acesso por ser conhecida: um token de API como o do linkbox, uma senha, uma
chave privada, uma string de conexão com banco que leva a senha dentro, o segredo de assinatura de
um webhook, um cookie de sessão que alguém colou num relato de bug. Uma chave pública não é
segredo, e um valor feito só para os testes, que não abre nada em lugar nenhum, também não, que é
exatamente o que esta aula dá aos testes em `tests/conftest.py`.

Um scanner não tem como saber quais strings dão acesso. Ele chuta a partir de duas coisas que uma
pessoa também notaria: o formato do valor, já que os tokens de um provedor têm prefixo e tamanho
conhecidos, e as palavras em volta dele, como `TOKEN`, `KEY` ou `PASSWORD`, junto com o quanto o
valor parece aleatório. A próxima seção roda um, e as linhas que ele imprime mostram os dois chutes
funcionando.
