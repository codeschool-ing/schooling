---
title: A job is an input, a query and an output
version: 1
---

**This section is taught from Microsoft's documentation, and nothing in it was run against Stream
Analytics.** There is no emulator of the service. What ran is Terraform checking a declaration of a
job offline, and the next three sections run the idea underneath with a short program of the
course's own, which is not Stream Analytics and says so each time.

**Azure Stream Analytics runs one SQL query over a stream, continuously, for as long as the job is
started.** A batch query reads a table that exists and finishes; a Stream Analytics query reads
events that have not happened yet and never finishes. Its answer is not a result set but another
stream: rows written to an output every time the query has something to say, such as every minute
for a count by minute.

Quitanda's first job counts checkouts per minute for a screen in the operations room. It has three
parts, and so has every job:

| part | what it is | Quitanda's |
|---|---|---|
| input | where events come from | the `clicks` event hub, read through a consumer group of its own |
| query | one statement, or several, in the Stream Analytics query language | count `/checkout` clicks per minute |
| output | where the rows go | a table in Azure SQL Database that the screen reads |

**A streaming input is an event hub, an IoT hub, or files arriving in Blob Storage or Data Lake
Storage.** A job may also have **reference inputs**, small tables it joins the stream against, read
from Blob Storage or Azure SQL Database and refreshed on a schedule; a list of Quitanda's stores
with their neighbourhoods is the kind of thing that goes there. The outputs are many, and the Azure
provider for Terraform has one resource type per kind, which is a fair list of them: Blob Storage,
Event Hubs, Service Bus queues and topics, Table storage, Azure SQL Database, Synapse, Cosmos DB,
Power BI and Azure Functions.

## The query

The language is SQL with a handful of additions for time. The job that counts checkouts:

```sql
SELECT System.Timestamp() AS window_end, COUNT(*) AS checkouts
INTO [checkouts-per-minute]
FROM [clicks] TIMESTAMP BY at
WHERE page = '/checkout'
GROUP BY TumblingWindow(minute, 1)
```

Read it as the SQL of `sql-databases`, with three differences. **`FROM [clicks]` and `INTO
[checkouts-per-minute]` name the job's input and output** by the aliases they were given when the
job was set up, not tables. **`TIMESTAMP BY at` says which field of the event holds the time the
thing happened**, and the next section is about why that one clause decides whether the count is
right. **`GROUP BY TumblingWindow(minute, 1)`** groups by one-minute windows of that time, and
`System.Timestamp()` is the end of the window a row belongs to. The fields `at` and `page` come out
of each event's JSON body: Stream Analytics, unlike Event Hubs, does look inside it, and the input
says the body is JSON.

A query cannot be tried against the service without a job, and a job needs a subscription. Microsoft
does publish a way to test a query locally, through the Stream Analytics extension for Visual
Studio Code, which runs it against a file of sample events on your computer. This course does not
install it, because it is an editor extension rather than something a terminal can record.

## Declaring the job

The job and its query, declared in Terraform. The query sits inside the file as a block of text, so
a review of the job's logic is a review of this file. In a directory of its own, as lesson 1 showed:

```sh
mkdir -p ~/azure/tf/asa && cd ~/azure/tf/asa
```

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "stream" {
  name     = "rg-quitanda-stream-prd"
  location = "brazilsouth"
}

resource "azurerm_stream_analytics_job" "checkouts" {
  name                                     = "asa-quitanda-checkouts-prd"
  resource_group_name                      = azurerm_resource_group.stream.name
  location                                 = azurerm_resource_group.stream.location
  compatibility_level                      = "1.2"
  streaming_units                          = 3
  events_out_of_order_max_delay_in_seconds = 20
  events_out_of_order_policy               = "Adjust"
  events_late_arrival_max_delay_in_seconds = 60
  output_error_policy                      = "Stop"

  transformation_query = <<QUERY
SELECT System.Timestamp() AS window_end, COUNT(*) AS checkouts
INTO [checkouts-per-minute]
FROM [clicks] TIMESTAMP BY at
WHERE page = '/checkout'
GROUP BY TumblingWindow(minute, 1)
QUERY
}
```

```
ana@laptop:~/azure/tf/asa$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/asa$ terraform validate -no-color
Success! The configuration is valid.
```

**Valid, and that says nothing about the query.** To the provider `transformation_query` is a string;
a misspelt `TumblingWindw` would pass `validate` too, and only the service would refuse it, when the
job is created or started. The inputs and outputs are resources of their own,
`azurerm_stream_analytics_stream_input_eventhub` and `azurerm_stream_analytics_output_mssql` among
them, and they are left out here because each needs a key or a password to the thing it reads or
writes, which is lesson 6's subject rather than this one's. The three `events_` lines are the
settings this lesson is about, and the section on late data comes back to them.
