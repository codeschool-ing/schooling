---
title: The churn a mobile app really has
version: 1
---

**On the web and in a subscription, churn is an event: somebody cancels. On a phone, it is the
absence of one.** People rarely uninstall in anger; they stop opening the app, and one day, needing
space for photos, they delete the icon they have not touched in weeks. The app sends no event on its
way out, because it is not running.

## The ways people leave that you never see

- **They stop opening it.** The only evidence is the rows that are not there in the cohort table.
- **They switch off its notifications.** The reminder of lesson 15 stops reaching them, and with it
  the most effective reason they had to come back. Both platforms let the app ask whether
  notifications are enabled, on its next launch.
- **They uninstall.** Neither platform tells the app itself. Firebase can report an
  `app_remove` event on Android, where the system notifies Google Play services; on iOS there is no
  equivalent. A push notification that can no longer be delivered is often the first sign, through
  the push service's response.
- **They uninstall to free space**, which lesson 18 shows is not a rare reason: the largest apps a
  person rarely uses are the first deleted.

## Defining churn so it can be counted

Because nothing marks the moment, churn is defined by a rule: **a person has churned when they have
been inactive for N days**, with N chosen to fit how the app is used. For the planner, whose people
study a few times a week, 14 days without an `app_open` is a sensible line: long enough not to count
a holiday week, short enough to notice within the month. A messaging app would use far fewer days,
an annual tax app far more.

**The churn rate is then the share of last period's active people who crossed that line**, and it is
always an estimate: some of those people come back after day 15, and the rule calls them churned and
then resurrected.
