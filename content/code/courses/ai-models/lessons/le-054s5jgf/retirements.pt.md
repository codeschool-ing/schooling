---
title: Um provedor aposentando em lote
version: 1
---

A série o não se aposenta sozinha. A mesma data na tabela leva junto a maior parte da linha GPT-4:

```
ana@desk:~/desk$ sheet retiring --provider openai | grep -E "  gpt-4"
2026-10-23  gpt-4                                              openai
2026-10-23  gpt-4-0613                                         openai
2026-10-23  gpt-4-1106-preview                                 openai
2026-10-23  gpt-4-turbo                                        openai
2026-10-23  gpt-4-turbo-2024-04-09                             openai
2026-10-23  gpt-4.1-nano                                       openai
2026-10-23  gpt-4.1-nano-2025-04-14                            openai
2026-10-23  gpt-4o-2024-05-13                                  openai
2027-01-20  gpt-4o-audio-preview-2024-12-17                    openai
2027-01-20  gpt-4o-audio-preview-2025-06-03                    openai
2027-01-20  gpt-4o-mini-audio-preview-2024-12-17               openai
```

Oito entradas em **23 de outubro de 2026**: o próprio GPT-4, o GPT-4 Turbo, uma versão datada do GPT-4o e
o **gpt-4.1-nano**, que nem é velho para esses padrões, ao lado das seis entradas da série o da seção 03.
Um provedor que limpa o catálogo faz isso em lotes, numa data, e todo produto que citava qualquer desses
modelos ganha a mesma semana para reagir.

Três hábitos, das aulas 2 e 5, que transformam isso de incidente em tarefa:

1. **Saiba quais identificadores o seu código cita.** Uma linha na configuração por tarefa (aula 6
   seção 04), para a lista do que depende de um modelo que vai sair ser uma busca, não uma
   investigação.
2. **Leia a lista de aposentadorias num calendário.** O `sheet retiring` é a cópia de terceiros; a
   página de descontinuações do próprio provedor e os e-mails que ele manda são a fonte. Uma vez por
   mês basta quando as aposentadorias são anunciadas com meses de antecedência.
3. **Mantenha a avaliação pronta para rodar.** Um substituto escolhido rodando os casos da aula 5
   contra dois ou três sucessores é trabalho de um dia; escolhido em cima da data, sem eles, é um
   palpite que vai para produção.

Repare também no que **não** está na lista. O `gpt-4.1` e o `gpt-4.1-mini` não têm data, enquanto o
irmão nano tem. A aposentadoria vai modelo a modelo, não família a família, e é por isso que o que se
confere é o identificador no código, não o nome da família.
