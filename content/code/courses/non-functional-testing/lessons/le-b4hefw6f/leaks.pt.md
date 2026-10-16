---
title: Como uma chave vai parar num repositório
version: 1
---

Um **segredo** é qualquer valor que permite a quem o tem agir como o sistema: uma chave de API do
provedor de pagamento, a senha de um banco de dados, a chave que assina os cookies de sessão, um
token da conta na nuvem. Ele funciona para qualquer um que o tenha, como a chave de uma porta, e o
problema é todo esse. Ninguém faz commit de um de propósito. **Ele chega ao repositório do jeito que
todo outro erro chega: numa tarde comum, com pressa, por um arquivo que parecia inofensivo.**

## Os caminhos de sempre

- **Um arquivo de configuração** que guarda a chave "só por enquanto", porque o código lê as
  configurações dali e a variável de ambiente ainda não foi criada.
- **Um teste ou um script** com a chave colada para experimentar o provedor uma vez, que entra no
  commit junto com a mudança que fez o teste passar.
- **Um arquivo que devia ter sido ignorado**: um `.env`, uma cópia da configuração de produção, um
  dump do banco, um notebook cujas células de saída imprimiram a configuração.
- **Um log ou uma mensagem de erro** que imprimiu a chave, salvo num arquivo que depois entrou num
  commit como exemplo.

Em todos os casos a chave está em **um commit**, e o commit seguinte costuma ser o que percebe.
Alguém a vê na revisão, apaga a linha e faz outro commit. O arquivo fica limpo. Esse segundo commit
não conserta nada que importe, porque o git é um histórico: o primeiro commit continua lá, com a
chave dentro, e qualquer um com uma cópia do repositório pode pedi-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l18-history\" aria-label=\"Um repositório desenhado como dois commits e os arquivos no disco. O commit 1 adiciona a chave; o commit 2 apaga a linha. Os arquivos no disco não guardam mais a chave, e uma varredura dos arquivos não acha nada. Uma varredura do histórico lê os dois commits e acha a chave no commit 1. Embaixo, quatro cópias feitas antes do apagamento: o seu clone, o clone de um colega, um fork e um cache de CI. Cada uma guarda o commit 1, com a chave, e apagar a linha não alcança nenhuma delas.\"><defs><marker id=\"l18-history-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-history-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">apagar a linha muda os arquivos, não o histórico</text><path d=\"M60.0 50.0 L460.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 46.0 L60.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 46.0 L460.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gitleaks git: todo commit</text><path d=\"M510.0 50.0 L680.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510.0 46.0 L510.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680.0 46.0 L680.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"595.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gitleaks dir: só estes</text><rect x=\"60.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"145.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">commit 1</text><text x=\"145.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">adiciona a chave</text><path d=\"M230.0 93.0 L286.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-history-nf-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">commit 2</text><text x=\"375.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">apaga a linha</text><rect x=\"510.0\" y=\"66.0\" width=\"170.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"595.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os arquivos no disco</text><text x=\"595.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem chave: nada achado</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">cópias feitas antes do apagamento</text><path d=\"M145.0 120.0 L145.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M70.0 140.0 L650.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M130.0 140.0 L130.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"70.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"130.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o seu clone</text><text x=\"130.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tem o commit 1</text><path d=\"M280.0 140.0 L280.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"220.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"280.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o clone de um colega</text><text x=\"280.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tem o commit 1</text><path d=\"M430.0 140.0 L430.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"370.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"430.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um fork</text><text x=\"430.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tem o commit 1</text><path d=\"M580.0 140.0 L580.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-history-nf-ah-amber)\"></path><rect x=\"520.0\" y=\"180.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"580.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cache de CI</text><text x=\"580.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tem o commit 1</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só revogar a chave torna todas inofensivas</text></svg>", "caption": "Apagar a linha cria um commit novo. O anterior continua com a chave, aqui e em toda cópia já feita.", "same": ["commit 1", "commit 2"]}
```

## Por que uma chave enviada é uma chave conhecida

Depois que um commit saiu da sua máquina, você não consegue listar todo mundo que o tem. Todo clone
tem o histórico, e também todo fork, todo runner que o compilou, todo cache, todo espelho, e o
notebook do colega que fez pull antes de você perceber. Num repositório público é pior e mais
rápido: robôs leem cada push nos serviços de hospedagem públicos procurando exatamente isso, e uma
chave válida publicada ali pode estar em uso em minutos.

**Então uma chave que chegou a um repositório compartilhado é tratada como conhecida por
estranhos**, tenha alguém a visto ou não. A correção segue daí, nesta ordem:

1. **Troque a chave.** Revogue-a no provedor, emita uma nova e implante a nova. A partir desse
   momento o valor vazado não abre nada, e toda cópia do histórico guarda uma chave morta.
2. **Veja o que ela fez.** O log do próprio provedor diz se a chave antiga foi usada, de onde e
   para quê, entre o push e a revogação. É isso que decide se o vazamento foi um incidente ou um
   quase acidente.
3. **Limpe o histórico, se for o caso.** Existem ferramentas que reescrevem cada commit sem o
   arquivo ou sem a linha: `git filter-repo` e o BFG Repo-Cleaner são as duas mais usadas. Reescrever
   muda todo hash depois daquele commit, exige um push forçado e um clone novo de todo mundo, e não
   alcança nenhuma das cópias que já existem. Arruma o repositório; não desvaza a chave.

Esta aula faz o primeiro passo no papel e o terceiro de jeito nenhum. O que importa é a ordem:
**uma equipe que reescreve o histórico e não troca a chave escondeu o vazamento e ficou com ele.**

## O que é do testador aqui

A parte do testador é a mesma do resto deste terço: anotar o que não pode acontecer e fazer algo
falhar quando acontece. Para segredos, isso são quatro linhas no plano de teste.

| o requisito | o que o segura |
|---|---|
| nenhum segredo em nenhum arquivo do repositório, em nenhum commit | um scanner de segredos sobre todo o histórico, a cada push |
| nenhum segredo num commit, para começo de conversa | o mesmo scanner sobre o que está no stage, antes de o commit existir |
| o código não guarda segredo, nem tem valor padrão para um | configuração vinda do ambiente ou de um gerenciador de segredos, revisada |
| um segredo encontrado é trocado, não só apagado | o procedimento de resposta, e um registro de cada caso |

O `account.py` já cumpre a terceira linha. **As primeiras linhas dele tiram do ambiente tudo o que
muda de uma máquina para outra**: onde fica o banco, para onde vão os uploads, quanto dura uma
sessão. Nada disso é segredo, e o arquivo pode ser lido, revisado e entrar inteiro num commit, que é
o que a aula 16 quis dizer com "nada secreto no arquivo". O resto desta aula constrói as outras três
linhas, num repositório pequeno seu, com uma chave dentro que ninguém jamais emitiu.
