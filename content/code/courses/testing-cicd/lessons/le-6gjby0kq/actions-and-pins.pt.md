---
title: Actions, e como fixá-las num commit
version: 1
---

Uma **action** é um passo que alguém empacotou para reuso: fazer checkout do código, instalar o
Python, enviar um arquivo. Você se refere a ela como `dono/repositório@ref`, e o GitHub baixa aquele
repositório naquela ref e o roda dentro do seu job, **com as permissões e os segredos do seu job ao
alcance**. Essa última parte é o motivo de a ref importar.

Há três jeitos de escrever:

| forma | exemplo | para onde aponta |
|---|---|---|
| um branch | `actions/checkout@main` | o que o branch tiver naquele momento |
| uma tag | `actions/checkout@v7` | para onde a tag foi movida por último |
| um commit | `actions/checkout@9c091bb…` | uma árvore exata, para sempre |

Um branch e uma tag podem ser movidos por quem controla o repositório da action. Se esse repositório
for comprometido, todo workflow que aponta para a tag roda o código novo na próxima execução, com
acesso a tudo o que esse workflow alcança. **Um hash de commit não pode ser movido.** Por isso o
workflow do `shipquote`, como o deste repositório, fixa cada action num commit completo e escreve a
versão ao lado como comentário: o hash para a máquina, o comentário para quem decide se está velho.

## Este repositório confere os próprios pins

O repositório que publica este curso tem uma ferramenta exatamente para isso, `tools/check-actions`,
e a roda na CI. Com `-offline` ela confere a metade da fixação sem buscar nada:

```
ana@laptop:~/schooling$ go run ./tools/check-actions -offline
· the runtimes were not read: -offline
16 action use(s) across the workflows, every one pinned to a commit and carrying the version it was cut from
```

Dezesseis usos de action nos workflows do repositório, todos fixados num commit com a versão ao lado.
Sem `-offline`, a ferramenta também busca o `action.yml` de cada action fixada e confere que ele não
declara um runtime JavaScript que o GitHub descontinuou, porque um pin mantém o código fixo enquanto a
plataforma embaixo dele se move.

## O custo de fixar

Pins não se atualizam sozinhos, então alguém precisa movê-los. Equipes costumam deixar um robô
propor as atualizações como pull requests, Dependabot ou Renovate, que mudam o hash e o comentário
juntos e rodam a CI no resultado. Um pin que ninguém atualiza é seguro e vai envelhecendo; a
ferramenta acima responde *está fixado?*, e os robôs respondem *está em dia?*. Na trilha `devsecops`,
o `secure-pipeline` trata a fundo da cadeia de suprimentos de um pipeline, e fixar é o ponto de
partida dele.
