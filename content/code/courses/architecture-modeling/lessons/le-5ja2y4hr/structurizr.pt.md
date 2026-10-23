---
title: "Structurizr: um modelo, todas as visões C4"
version: 1
---

**O Structurizr descreve um sistema de software uma vez, como um modelo de pessoas, sistemas,
contêineres e das relações entre eles, e depois deriva os diagramas C4 da aula 3 como visões desse
modelo.** Simon Brown, que criou o C4, criou o Structurizr para acompanhá-lo. O formato de texto
dele é a **Structurizr DSL**.

## O modelo do Carcará

Salve isto como `workspace.dsl`:

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

Leia-o com a aula 3 ao lado:

- o bloco **`model`** declara cada elemento uma vez, com as palavras do C4: `person`,
  `softwareSystem`, `container`, cada um com um nome, uma descrição e, para os contêineres, uma
  tecnologia. A última string de uma linha é uma **tag**, como `Database` ou `External`, que os
  estilos podem usar;
- cada **relação** é escrita uma vez, `origem -> destino "descrição" "tecnologia"`;
- o bloco **`views`** pede dois diagramas, um de contexto do sistema e uma visão de contêineres, e
  `include *` deixa a ferramenta decidir quais elementos entram em cada um: tudo o que está ligado ao
  sistema no primeiro, tudo o que está dentro dele e ligado a ele no segundo.

A relação da API de passagens com o gateway de pagamento é escrita uma vez. **Ela aparece nas duas
visões, e não tem como aparecer diferente nelas**, porque só existe uma.

## Validando e exportando

Esta aula roda o Structurizr pela imagem de contêiner, com a sua pasta montada dentro dela. Dois
detalhes importam: `--user` faz os arquivos exportados serem seus, e a pasta de saída precisa
existir antes.

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

`validate` não imprime nada quando o modelo está correto. `export` gravou um arquivo Mermaid por
visão, que o renderizador da seção do Mermaid consegue desenhar:

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

O último comando conta a descrição da relação com o gateway de pagamento em cada arquivo. Ela foi
escrita uma vez, no modelo, e está nas duas visões: na visão de contexto como relação do sistema de
passagens, na visão de contêineres como relação da API. Mude essa descrição no `workspace.dsl`,
exporte de novo, e as duas visões mudam. Essa é a propriedade que a aula 3 pediu e que uma
ferramenta de desenho não consegue dar.

## O mesmo programa como arquivo

O Structurizr também é publicado como um único arquivo Java, `structurizr.war`, que roda com o Java
21 como `java -jar structurizr.war export -w workspace.dsl -f mermaid -o diagrams`. Este curso gravou
só a imagem de contêiner. A imagem também traz um servidor web local para navegar por um workspace
com os diagramas dispostos, iniciado com o comando `local`; a documentação dele está no site do
projeto e não foi coberta aqui.
