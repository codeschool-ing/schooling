---
title: Indicadores de comprometimento
version: 1
---

Um **indicador de comprometimento (IoC)** é um fato observável que, visto no seu ambiente, sugere que um
comprometimento já aconteceu: um endereço, um domínio, o hash de um arquivo, um nome de arquivo, uma chave de
registro, um user agent. O relatório da aula 8 trazia três. Eles servem para exatamente uma pergunta, **"já
vimos isto aqui?"**, e respondem depressa: uma consulta, não uma investigação.

A fraqueza deles é que cada um é um valor único e concreto, e valores mudam. O **hash** de um arquivo é o
caso extremo:

```
ana@soc:~/week$ printf 'quarterly figures, version 1\n' > a.txt
ana@soc:~/week$ printf 'quarterly figures, version 2\n' > b.txt
ana@soc:~/week$ sha256sum a.txt b.txt
ff9443882788a453030f3813ef6c6e6ba3f4066f050e5bde8092177f2ff099cd  a.txt
99bc73d19e5480a4c68c5188874c2329b563923d5e92453a5648b26b40ce677b  b.txt
```

Dois arquivos que diferem num caractere, `1` contra `2`, e as impressões SHA-256 deles não têm nada em comum.
Um hash identifica um arquivo exato com precisão completa, e é por isso que é a melhor evidência num laudo
forense (aula 16) e a detecção mais fraca que existe: quem fez o arquivo muda um byte e toda lista com o hash
antigo fica desatualizada.

IoCs vêm em três graus de utilidade:

| grau | exemplo | como é usado |
|---|---|---|
| **atômico** | `203.0.113.66`, um hash | consultado como está; verdadeiro ou falso, sem contexto |
| **calculado** | um hash, um padrão derivado de uma amostra | exige o mesmo cálculo do seu lado |
| **comportamental** | "muitas contas a partir de uma origem, depois sucesso" | exige uma regra, e é o assunto da terceira seção desta aula |

Os dois primeiros são onde a maioria das listas compartilhadas para. O terceiro é onde a detecção dura.
