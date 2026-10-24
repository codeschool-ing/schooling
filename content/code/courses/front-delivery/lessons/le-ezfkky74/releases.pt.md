---
title: Releases
version: 1
---

**Uma release é o nome de um build, e todo relatório o carrega, para que uma pilha seja lida com os maps do
build que a produziu e para que dê para ver um conserto funcionar.** O mapeamento da seção anterior só
funcionou porque o relatório dizia `release` e uma pasta de maps tinha esse nome. Leia uma pilha com os
maps de outro build e as posições apontam para outro código, com toda a confiança e errado.

## Qual nome

O hash do commit é o natural: ele já identifica o código com exatidão, não custa nada, e é a partir dele
que o pipeline da aula 3 constrói. Uma equipe que marca versões com tags pode usar a tag, como a biblioteca
da aula 7 fez; o que importa é que um nome queira dizer um build, e que o mesmo nome seja definido no build
e nos maps.

## No pipeline

O workflow da aula 3 constrói o planner a cada push no `main`. Um deploy com coletor definiria as três
variáveis ali e guardaria os maps como artefato da própria execução, fora do site. As linhas acrescentadas,
que não foram executadas para este curso, são estas:

```yaml
      - name: Build
        run: npm run build
        env:
          VITE_GRAPHQL_URL: /graphql
          VITE_ERRORS_URL: /errors
          VITE_RELEASE: ${{ github.sha }}
      - name: Keep the source maps out of the site
        run: mkdir maps && mv dist/assets/*.map maps/
      - name: Upload the source maps
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: source-maps-${{ github.sha }}
          path: maps/
```

`github.sha` é o hash completo do commit. Os builds locais do planner usaram o curto; os dois servem,
desde que um tipo só seja usado em todo lugar.

## O que um nome de release compra

- **Qual build está quebrado.** Um erro que começou numa release, e não antes, aponta para o commit que o
  introduziu.
- **Se um conserto funcionou.** Uma mensagem que para de chegar da release depois do conserto, enquanto
  abas antigas abertas continuam mandando-a da release anterior, é um conserto confirmado.
- **Quem é afetado.** O build antigo de um site estático continua rodando em toda aba aberta antes do
  deploy, às vezes por dias. Relatórios de uma release antiga são essas abas, e não um bug novo.
