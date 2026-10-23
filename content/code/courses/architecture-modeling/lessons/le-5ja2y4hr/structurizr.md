---
title: Structurizr: one model, every C4 view
version: 1
---

**Structurizr describes a software system once, as a model of people, systems, containers and the
relationships between them, and then derives the C4 diagrams of lesson 3 as views of that model.**
Simon Brown, who created C4, created Structurizr to go with it. Its text format is the **Structurizr
DSL**.

## Carcará's model

Save this as `workspace.dsl`:

```
workspace "Carcará" "Ticket sales and boarding" {

    model {
        passenger = person "Passenger" "Buys tickets and boards buses"
        driver = person "Driver" "Checks tickets at the door"

        ticketing = softwareSystem "Carcará ticketing" "Sells and checks bus tickets" {
            webapp = container "Passenger web app" "Search, buy, show tickets" "TypeScript"
            api = container "Ticketing API" "Bookings, holds, payments" "Kotlin, Spring Boot"
            holds = container "Seat holds" "10-minute holds" "Redis" "Database"
            db = container "Booking database" "Bookings and tickets" "PostgreSQL" "Database"
            boarding = container "Boarding app" "Checks tickets offline" "Android"
        }

        gateway = softwareSystem "Payment gateway" "Charges cards and Pix" "External"

        passenger -> webapp "Buys tickets using" "HTTPS"
        webapp -> api "Creates bookings and payments" "HTTPS/JSON"
        api -> holds "Holds seats in" "RESP"
        api -> db "Reads and writes bookings" "SQL"
        api -> gateway "Charges payments through" "HTTPS"
        driver -> boarding "Scans tickets with"
        boarding -> api "Downloads ticket lists from" "HTTPS"
    }

    views {
        systemContext ticketing "Context" {
            include *
            autolayout lr
        }
        container ticketing "Containers" {
            include *
            autolayout lr
        }
        styles {
            element "External" {
                background #999999
            }
        }
    }
}
```

Read it against lesson 3:

- the **`model`** block declares every element once, with C4's words: `person`, `softwareSystem`,
  `container`, each with a name, a description and, for containers, a technology. The last string
  on a line is a **tag** such as `Database` or `External`, which styles can use;
- each **relationship** is written once, `source -> destination "description" "technology"`;
- the **`views`** block asks for two diagrams, a system context and a container view, and
  `include *` lets the tool decide which elements belong in each: everything connected to the system
  in the first, everything inside it and connected to it in the second.

The relationship from the ticketing API to the payment gateway is written once. **It appears on both
views, and it cannot appear differently on them**, because there is only one of it.

## Validating and exporting

This lesson runs Structurizr from its container image, with your folder mounted inside it. Two
details matter: `--user` makes the exported files yours, and the output folder must exist first.

```
ana@vm:~/diagrams$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/usr/local/structurizr structurizr/structurizr:2026.09.19 validate -w workspace.dsl
ana@vm:~/diagrams$ mkdir c4
ana@vm:~/diagrams$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/usr/local/structurizr structurizr/structurizr:2026.09.19 export -w workspace.dsl -f mermaid -o c4
05:07:00.963 [main] INFO com.structurizr.command.ExportCommand -- Exporting workspace from workspace.dsl
05:07:01.100 [main] INFO com.structurizr.command.ExportCommand -- Exporting with MermaidDiagramExporter
05:07:01.129 [main] INFO com.structurizr.command.ExportCommand -- Writing /usr/local/structurizr/c4/structurizr-Context.mmd
05:07:01.130 [main] INFO com.structurizr.command.ExportCommand -- Writing /usr/local/structurizr/c4/structurizr-Containers.mmd
05:07:01.130 [main] INFO com.structurizr.command.ExportCommand -- Finished
```

`validate` prints nothing when the model is sound. `export` wrote one Mermaid file per view, which
the renderer from the Mermaid section can draw:

```
ana@vm:~/diagrams$ ls c4
structurizr-Containers.mmd
structurizr-Context.mmd
ana@vm:~/diagrams$ npx mmdc -i c4/structurizr-Containers.mmd -o c4/containers.svg
Generating single mermaid chart
ana@vm:~/diagrams$ grep -c "Charges payments through" c4/*.mmd
c4/structurizr-Containers.mmd:1
c4/structurizr-Context.mmd:1
```

The last command counts the description of the relationship to the payment gateway in each file. It
was written once, in the model, and it is in both views: on the context view as the ticketing system's
relationship, on the container view as the API's. Change that description in `workspace.dsl`, export again,
and both views change. That is the property lesson 3 asked for and a drawing tool cannot give.

## The same program as a file

Structurizr is also published as a single Java archive, `structurizr.war`, that runs with Java 21 as
`java -jar structurizr.war export -w workspace.dsl -f mermaid -o diagrams`. This course recorded
the container image only. The image also contains a local web server for browsing a workspace with
its diagrams laid out, started with the `local` command; its documentation is on the project's
website and was not covered here.
