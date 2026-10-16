---
title: What Shield Advanced adds
version: 1
---

Shield Advanced is a subscription, bought once for the AWS organisation and applied to the resources
named in it. What it adds over Standard is mostly not more filtering. It is **people, money back and
automation**, and each is worth knowing on its own terms:

| it adds | what that is |
|---|---|
| detection tuned to the resource | Shield learns each protected resource's normal traffic and detects smaller attacks against it; with a Route 53 health check attached, it uses the application's health as well as the traffic |
| automatic application-layer mitigation | when an HTTP flood is detected, Shield writes WAF rules into the resource's web ACL to block it, in `Count` or `Block` as configured, and removes them afterwards |
| the Shield Response Team | AWS's DDoS specialists, reachable during an attack, and, with **proactive engagement**, calling the team when a protected resource's health check fails; it requires a Business or Enterprise support plan |
| cost protection | credits for the scaling charges an attack causes on protected resources, the load balancers, instances and distributions that grew to absorb it |
| visibility | attack reports with vectors, sizes and durations, in `list-attacks` and in CloudWatch metrics in the namespace `AWS/DDoSProtection` |
| WAF included | for protected resources, AWS documents the web ACL, its rules and its requests as included in the subscription |

## Cost protection, read carefully

Cost protection is the line most often misread. It is **a credit, requested after the attack**, for the
extra usage a DDoS caused on resources that were protected at the time, and it covers scaling, not
everything: a credit request names the attack Shield recorded, and an attack nobody protected against
or Shield did not detect is not covered. For a service that scales automatically, the bill of a week's
attack can be the largest number in the year, and this is the insurance against it.

## What Advanced does not do

It does not make an application that falls over at ten times its normal traffic survive a hundred
times. The protections are the same three layers as before: Standard's at the edge, WAF at layer 7,
and enough capacity, or caching, to answer what gets through. Shield Advanced makes the second layer
quicker to adjust during an attack, puts experts beside the team while it happens, and pays for the
third. A team that has not done lesson 15's work buys little with lesson 16's subscription.
