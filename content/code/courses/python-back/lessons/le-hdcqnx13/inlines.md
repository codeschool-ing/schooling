---
title: Inlines: the rows that belong to a row
version: 1
---

The registrations of an event belong to it, and an organiser looking at an event wants to see them
there rather than in another list filtered by event. An **inline** does that. `RegistrationInline`
in the admin file is a `TabularInline` for `Registration`, listed in the event's `inlines`:

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

The event's own fields come first, as a form, and the inline adds a table at the bottom: one row
per registration, with its fields as inputs and `Created at` read-only because it is in
`readonly_fields`. The empty last row is for adding one, and **every row has a `Delete?` box**, so
an organiser can cancel a registration from the event's page and save.

The admin knew which registrations to show, and which event a new one belongs to, from the foreign
key alone. A model with two foreign keys to `Event` would need `fk_name` to say which one the
inline follows.

`TabularInline` lays rows out as a table; `StackedInline` gives each row a form of its own, for
models with many fields. Both handle validation the way the main form does, row by row.

**The empty row is a door, though**, and it opens onto the registrations table without going
through lesson 4's `register`. The last section of this lesson walks through it and closes it.
