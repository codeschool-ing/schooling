---
title: Refreshing it and handing it over
version: 1
---

**A dashboard shows the data as it was at its last refresh, and it travels with all of it.** Both
facts are invisible on the screen. The owner sees four cards and three charts that look current
whether the data is from yesterday or from March, and nothing on the sheet says that the file also
holds 108 sales and the name of every customer.

## Refreshing

The pivot tables read the data model, and the model is filled from the tables and queries that
lesson 15 loaded into it. **Data › Refresh All** runs everything, in order: the queries reload their
sources, the model takes the new rows, and the pivots and charts follow. It is the button to press
because it is the one that reaches every query, the model and every pivot in one go.

A workbook can also refresh itself when it is opened. In **Data › Queries & Connections**,
right-click a query, open its **Properties**, and tick **Refresh data when opening the file**. It
costs the reader a few seconds at every opening, and it means the numbers are never older than the
sources the queries read.

The title's **data to** date is what tells the reader how fresh the screen is. After a refresh it
should be the date of the last sale that exists. If the sources gained sales in July and the title
still says 23 June 2026, the refresh did not reach them, and every card is stale with it.

## Saving it the way it should open

A workbook opens in the state it was saved in, and that includes the slicer. Save it with
`Wholesale` selected and the owner opens a dashboard of one channel, with nothing on the cards to
say that the other two are missing.

Before saving the copy that leaves, put it in its default state:

1. **Data › Refresh All**, and check the date in the title.
2. Clear the slicer, so every channel is selected.
3. Set the timeline to the period the dashboard is for.
4. Go to `Dashboard`, select **A1**, and save. The workbook opens on the sheet and cell it was saved
   on.

## Who should have the file

**Everything the dashboard summarises is inside it**, in the data sheets, in the hidden `Calc`
sheet and in the model. A dashboard sent by e-mail to somebody who should see only totals gives them
every sale and every customer as well. Café Serra's customers are companies, but a shop whose
customers are people would be sending a list of them, and in Brazil that is personal data under the
LGPD whether or not anyone opens the sheet.

Two ways round it, depending on what the reader needs:

| the reader needs | send them |
|---|---|
| to see the numbers | a PDF of the dashboard, from **File › Export › Create PDF/XPS**: the numbers and charts as they were, no slicers and no data |
| to filter and explore | access to the one copy, kept on OneDrive or SharePoint and shared with the people who should have it, instead of a copy in their inbox |

The PDF is a photograph: it cannot be filtered and it never refreshes, which is exactly right for
somebody who should only see it. Lesson 18 comes back to the shared copy, because many people
working on one workbook is where Excel starts to strain.

## Which Excel opens it

A workbook with a data model needs Excel for Windows to refresh the model or change it, as the
table in lesson 1 section 03 says. What a reader on a Mac or in a browser can do with one, in
viewing and filtering, has changed between versions, so **open the file in the reader's Excel before
you send it**, not after they write back to say the cards are empty.
