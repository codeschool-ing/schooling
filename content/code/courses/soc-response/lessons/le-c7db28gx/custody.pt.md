---
title: Custódia da imagem
version: 1
---

A aula 3 apresentou a **cadeia de custódia** para logs: um registro de quem ficou com uma evidência, de quando
até quando, e o que fez com ela. Uma imagem é a mesma coisa, com mais em jogo: ela pode ser o que se mostra a um
juiz, a uma seguradora ou à ANPD. Para a imagem que acabou de ser feita, o registro fica assim:

| campo | valor |
|---|---|
| caso | INC-2026-014 |
| item | 001, disco de dados do `files` |
| adquirida por | diego, com a ana como testemunha |
| quando | a data e a hora da aquisição, com o fuso |
| como | dispositivo loop somente leitura; `dd` (bruta) e `ewfacquire` (E01, EnCase 6) |
| SHA-256 | o hash da saída da aquisição, igual para o dispositivo, a imagem bruta e o E01 |
| MD5 | o guardado no E01 |
| guardada | onde o original e a imagem ficam, e quem consegue abrir esse lugar |
| transferências | toda entrega posterior: de quem, para quem, quando, por quê, e o hash conferido em cada uma |

As regras que fazem o registro valer a pena são poucas:

- **Duas cópias da imagem, guardadas em lugares separados**, e nenhuma delas aberta. A análise usa uma
  **terceira**, a cópia de trabalho, conferida contra o mesmo hash antes de o trabalho começar.
- **O hash é conferido a cada entrega**, e a conferência é anotada. Uma transferência sem conferência de hash é
  uma lacuna na cadeia.
- **O original é lacrado e guardado**, se for possível. Na quinta o servidor continua em serviço, então o original
  é a imagem feita dele, e o registro diz isso.

Um registro errado é corrigido por um registro novo que diz o que estava errado, nunca editando o antigo: a mesma
regra do log de auditoria que só aceita acréscimos, pelo mesmo motivo. E o registro começa **no momento da
aquisição**. Escrito no dia seguinte, de memória, é a primeira coisa sobre a qual o advogado da outra parte
pergunta.
