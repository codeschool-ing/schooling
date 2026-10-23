---
title: Inlines: as linhas que pertencem a uma linha
version: 1
---

As inscrições de um evento pertencem a ele, e quem organiza e olha um evento quer vê-las ali, não em
outra lista filtrada por evento. Um **inline** faz isso. O `RegistrationInline` do arquivo do admin é
um `TabularInline` para `Registration`, listado nos `inlines` do evento:

```
ana@vm:~/agenda$ page /admin/events/event/3/change/ | sed -n "/^Change event/,/^\[Save\]/p"
Change event

Testing dojo

  * History

Title: [Testing dojo        ]
Slug: [testing-dojo        ]
Starts at:

Date: [2026-11-26]
Time: [19:00:00]

Venue: [Community Centre, ro]
Capacity: [20                  ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
             [                                        ]
Description: [                                        ]

Registrations

                                Name                  Email                Created at       Delete?
Carla for Testing dojo                                               Oct. 16, 2026, 8:11
                       [Carla               ] [carla@example.org   ] p.m.                   [ ]

Davi for Testing dojo                                                Oct. 16, 2026, 8:11
                       [Davi                ] [davi@example.org    ] p.m.                   [ ]

                       [                    ] [                    ] -

[Save] [Save and add another] [Save and continue editing] Delete
```

Os campos do próprio evento vêm primeiro, como formulário, e o inline acrescenta uma tabela no fim:
uma linha por inscrição, com os campos como inputs e `Created at` só de leitura porque está no
`readonly_fields`. A última linha vazia é para incluir uma, e **toda linha tem uma caixa `Delete?`**,
então quem organiza pode cancelar uma inscrição pela página do evento e salvar.

O admin soube quais inscrições mostrar, e a que evento uma nova pertence, só pela chave estrangeira.
Um modelo com duas chaves estrangeiras para `Event` precisaria do `fk_name` para dizer qual o inline
segue.

O `TabularInline` organiza as linhas como tabela; o `StackedInline` dá a cada linha um formulário
próprio, para modelos com muitos campos. Os dois tratam a validação como o formulário principal, linha
a linha.

**Mas a linha vazia é uma porta**, e ela dá na tabela de inscrições sem passar pelo `register` da aula
4. A última seção desta aula atravessa essa porta e a fecha.
