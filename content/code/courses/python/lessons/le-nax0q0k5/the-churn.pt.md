---
title: A aula que envelhece mais rápido, e a parte que não envelhece
version: 2
---

**Esta é a única leitura do curso com prazo de validade.** Dizer isso é o ponto: a recomendação
no topo desta aula está certa hoje, e a equivalente a ela já esteve errada duas vezes nos últimos
cinco anos.

| ferramenta ou formato | o que significou |
|---|---|
| `setup.py` + `requirements.txt` | o arranjo de que tudo partiu |
| `pipenv` | recomendado pelo guia oficial de empacotamento |
| `poetry` | o que a maior parte dos projetos novos usou depois |
| `pyproject.toml` | padronizado; o `setup.py` começa a desaparecer |
| `pip-tools` | como se travava com o pip sozinho |
| `[project]` | a tabela de metadados vira especificação |
| `hatch`, `pdm` | mais ferramentas, lendo a mesma tabela |
| `uv` | uma ordem de grandeza mais rápido que todas |
| `poetry` 2 | adota o `[project]`; os dois convergem |

Isso é uma ordenação e não um conjunto de datas, e basta para fazer o ponto: toda linha foi a
recomendação sensata enquanto durou, e seguir qualquer uma delas deixa você com um repositório
que alguém tem de migrar.

## O que de fato mudou, e o que não mudou

**O arquivo não mudou.** O `[project]` tem um nome, uma versão, `requires-python` e
`dependencies`, e tudo acima é um programa diferente lendo as mesmas quatro chaves. Um projeto
que se declara na tabela padrão sobreviveu a cada uma dessas mudanças sem edição.

**O formato da trava muda com a ferramenta.** `Pipfile.lock`, `poetry.lock`, `requirements.txt`
do `pip-compile`, `uv.lock` — quatro formatos para uma ideia, e nenhum deles lê o do outro. É essa
a parte que faz de uma migração uma migração.

**Os verbos não mudaram.** Acrescentar uma dependência, resolver, travar, sincronizar, rodar.
Toda uma dessas ferramentas tem esses cinco, com nomes diferentes, e saber o que eles querem dizer
se transfere sem mudança.

## O que fazer a respeito

- **Aprenda o arquivo, não a ferramenta.** A tabela `[project]` é uma especificação e vai
  sobreviver ao que quer que você instale esta semana.
- **Não migre um projeto que funciona porque existe algo mais rápido.** A migração custa um dia e
  uma classe de defeito que só aparece na implantação; a velocidade poupa segundos.
- **Recorra sim à ferramenta atual num projeto novo.** O custo de estar na antiga é pago depois,
  por quem entrar.
- **Desconfie de um tutorial sem data.** Metade do conselho sobre empacotamento na internet está
  correto para um ano que já passou, e nenhum deles diz qual ano.

## E a ressalva honesta

O `uv` é o mais novo deles. Ele é muito bom e é de uma empresa só, e as três últimas respostas
para esta pergunta também eram muito boas no dia em que alguém as anotou. O arquivo é a aposta que
vale fazer; a ferramenta é uma escolha que você talvez tenha de fazer de novo.
