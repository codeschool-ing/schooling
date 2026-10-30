---
title: Templates, e o que uma equipe não pode pular
version: 1
---

**Um template é um pedaço de YAML num arquivo próprio que uma esteira inclui.** Três equipes que copiam as
mesmas oito linhas de preparação de testes terão três versões diferentes delas dentro de um ano; um template
transforma as oito linhas num arquivo só, com parâmetros. Este é de passos:

```yaml
# templates/python-test.yml
parameters:
  - name: pythonVersion
    type: string
    default: '3.12'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: ${{ parameters.pythonVersion }}
  - script: python -m pip install -r requirements.txt
    displayName: Install
  - script: python -m unittest discover -s tests
    displayName: Test
```

A esteira o inclui onde antes ficavam os passos, e passa o parâmetro:

```yaml
      - job: test_and_push
        steps:
          - template: templates/python-test.yml
            parameters:
              pythonVersion: '3.12'
          - task: Docker@2
            # ...as before
```

`${{ parameters.pythonVersion }}` é uma **expressão de template**, e as chaves dobradas importam: ela é
resolvida quando o YAML é compilado, antes de existir qualquer agente, então pode decidir quais passos
existem. `$(Build.SourceVersion)`, com cifrão e parênteses, é uma **macro**, preenchida em tempo de
execução, então só consegue mudar um valor dentro de um passo. Confundir as duas é o bug de template mais
comum: uma `$(variavel)` usada para decidir se um estágio existe ainda é uma string literal quando essa
decisão é tomada.

Templates vêm em quatro tipos, conforme o que contêm: **estágios**, **jobs**, **passos** e **variáveis**.
Uma esteira os inclui no nível correspondente, e um template pode incluir outros.

## Um template que a esteira tem de estender

Incluir um template é voluntário: uma equipe pode apagar a linha. **`extends` é a forma que pode virar
obrigatória.** A esteira da loja estende um template da equipe de plataforma, guardado em outro repositório
e referenciado por uma tag:

```yaml
# azure-pipelines.yml, in the shop's repository
resources:
  repositories:
    - repository: platform
      type: git
      name: platform/pipeline-templates
      ref: refs/tags/v3

extends:
  template: secure-build.yml@platform
  parameters:
    buildSteps:
      - script: python -m unittest discover -s tests
```

O `secure-build.yml` da equipe de plataforma decide o que roda em volta dos passos que recebe: talvez rode
uma varredura de dependências antes e recuse um passo que seja uma `task` que ele não permite. Depois, a
proteção que torna isso obrigatório vai no **ambiente** ou na service connection, como uma verificação
chamada **required template**: um deploy em `shop-production` é recusado a menos que a execução estenda o
`secure-build.yml` daquele repositório. Essa verificação é o assunto da lição 3. O ponto aqui é a divisão de
trabalho: a equipe da aplicação é dona dos seus passos, a de plataforma é dona da moldura, e nenhuma muda a
da outra em silêncio.

Os dois arquivos acima **não foram executados**, pelo mesmo motivo da esteira: não há organização do Azure
DevOps no laboratório.
