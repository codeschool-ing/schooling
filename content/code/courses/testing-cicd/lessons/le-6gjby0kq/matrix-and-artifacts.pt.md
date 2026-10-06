---
title: A matriz e os artefatos, em YAML
version: 1
---

O hook da aula 5 rodou seis células em dois laços aninhados e gravou os resultados de cada célula num
diretório. O workflow do `shipquote` diz o mesmo em poucas linhas, e o serviço faz o resto.

```yaml
    strategy:
      fail-fast: false
      matrix:
        python: ["3.11", "3.12", "3.13"]
        tz: ["America/Sao_Paulo", "UTC"]
```

O GitHub multiplica as listas: **cada combinação vira um job próprio**, na própria máquina, rodando em
paralelo, cada um com `matrix.python` e `matrix.tz` preenchidos. Seis jobs, com os valores no nome
na página da execução. Quando uma combinação não deve rodar, ou uma a mais deve, a matriz aceita
listas `exclude` e `include`:

```yaml
      matrix:
        python: ["3.11", "3.12", "3.13"]
        tz: ["America/Sao_Paulo", "UTC"]
        exclude:
          - python: "3.12"
            tz: "UTC"
```

Isso daria cinco jobs. O esboço não está no `shipquote`; mostra como uma equipe mantém uma matriz só
com as células que valem o custo, como a aula 5 seção 06 pediu.

## Artefatos entre jobs

Jobs não dividem arquivos: cada um roda numa máquina diferente, e a máquina é descartada no fim. Para
passar algo de um job para outro, o primeiro **envia** como artefato e o segundo **baixa**. No
`shipquote` cada célula da matriz envia o relatório JUnit e o arquivo `.coverage.*` como `results-0`
a `results-5`, e o job de cobertura baixa todos:

```yaml
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          pattern: results-*
          merge-multiple: true
      - run: coverage combine && coverage report
```

`merge-multiple` põe os arquivos dos seis artefatos num diretório só, que é o que o `coverage combine`
espera. Dois detalhes do passo de envio passam fácil despercebidos:

- **`include-hidden-files: true`**: os arquivos `.coverage.*` começam com ponto, e a action de envio
  deixa arquivos ocultos de fora se não for avisada. Sem isso, o job de cobertura combinaria nada e
  não relataria nada, com todos os jobs verdes.
- **`if: always()`** no envio e no job de cobertura: por padrão um passo ou job é pulado quando algo
  antes dele falhou, e uma execução com falha é exatamente quando os relatórios importam.

Artefatos têm um prazo de retenção, definido por repositório ou por envio, depois do qual o serviço
os apaga. Um relatório de que alguém pode precisar meses depois, os resultados de teste de um release
para uma auditoria, fica guardado num lugar da própria equipe, e não no armazenamento temporário de
um serviço de CI.
