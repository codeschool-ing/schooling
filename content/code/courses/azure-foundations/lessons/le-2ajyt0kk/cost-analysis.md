---
title: Cost analysis, and the questions it answers
version: 1
---

**A budget tells you that something is wrong; cost analysis is where you find out what.** It is the
part of Cost Management that draws the bill as charts and tables you can cut by any dimension:
subscription, resource group, resource, service, region, tag. **Nothing in this section was run**:
cost analysis reads the costs of a real billing account, and the lab has none. There are no
screenshots either, since the screens are Microsoft's and change. What follows is how it works, from
Microsoft's documentation, and the order to ask it questions in.

## A scope, a period, a grouping

Every view in cost analysis is the same three choices, and getting the first one wrong is the common
mistake:

- **the scope**, which is one of the boxes of lesson 2: a management group, a subscription, a resource
  group, or a billing account above them. The view shows only costs inside it, and you see only the
  scopes you hold a role on. A developer with access to one resource group who opens cost analysis
  sees that group's cost and believes it is the company's;
- **the period**, by default the current calendar month, with a daily or a monthly granularity;
- **the grouping and the filters**: group by service to see *what kind* of thing costs money, by
  resource to see *which one*, by a tag to see *whose*, which is lesson 15.

Microsoft ships a set of views to start from. The **smart views**, such as *Services* and
*Resources*, open with the month's cost and its forecast at the top and a table of the biggest
contributors underneath. Each row drills down: from a subscription to its groups, from a group to
its resources, from a resource to its meters. The **customisable views**, among them *Accumulated
costs* and *Daily costs*, are charts you can change and save.

## The order to ask in

When the forecast alert of the previous sections fires, the same four questions find the cause
almost every time:

1. **Daily costs for the month.** A cost that grew steadily is a workload growing. A step on one day
   is something that was created, or changed, on that day, and the date is the first clue.
2. **Group the step day by service.** It names the kind of thing: virtual machines, bandwidth, a
   database, a gateway.
3. **Group by resource, filtered to that service.** It names the thing, with its resource id, which
   lesson 2 taught you to read: the subscription and the resource group are in it, and they usually
   say whose it is.
4. **Open the resource's own history**, the activity log, to find who created or changed it.
   The `azure-operations` course covers the activity log in its lesson 21; here it is enough to
   know that every write to Resource Manager is recorded there with the identity that made it.

**Daily data is a day late, as the budget's was.** Cost analysis reads the same data the budget does,
so a step that started this morning is not on the chart yet. Microsoft's documentation also advises
checking the views weekly as a habit, and daily for the first week or two after a change.

## Anomalies, found for you

For a subscription, cost analysis also looks for **anomalies**: days whose cost is out of line with
the subscription's own recent pattern. The smart views report them among their insights, or say
*No anomalies detected*, and an **anomaly alert** can e-mail somebody when one is found. It is a
different kind of alarm from a budget: a budget compares the month with a number somebody chose, an
anomaly compares a day with the subscription's own history. A forgotten machine that costs a little
every day never looks anomalous, and a budget catches it; a sudden spike well under the budget does,
and the budget stays quiet. The shop keeps both.

## Actual cost and amortised cost

Every view can show the cost two ways, and the difference is the subject of lesson 14:

- **actual cost** is what was charged, on the day it was charged. A reservation bought for a year,
  paid up front, is one large line on the day of purchase;
- **amortised cost** spreads that purchase over the days it covers, and charges each day's share to
  the resources that used it.

Budgets evaluate actual cost. For the question *who spent what*, amortised is the honest one, because
the resource that benefits from a reservation is charged its share, and the day of purchase does not
look like a disaster. Choose before you compare two months, and say which one a chart shows.
