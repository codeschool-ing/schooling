---
title: The threads are a resource too
version: 1
---

A service has limits that nobody wrote in its design: **a fixed number of things it can do at once**.
Threads in a pool, connections to its database, memory for requests in flight, file descriptors. Each
has a number, usually a framework's default: 200 threads in Tomcat, 10 connections in HikariCP's pool,
a single worker process in Gunicorn. Below that number the service is fast; at it, every new request waits.

Lesson 5 named the dangerous case. A caller waiting on a synchronous call holds one of those things while
it waits. When a dependency answers in 20 milliseconds, a thread is held for 20 milliseconds and the
pool turns over quickly. When the same dependency starts taking five seconds, every request that calls
it holds a thread for five seconds, and at a few requests a second **the whole pool is soon waiting on
one slow service**. Nothing has failed, and nothing else can run.

That is how a failure spreads through a system without any error being raised: the slow service makes
its callers slow, their callers time out waiting for them, and the outage moves outwards one hop at a
time. It is called a **cascading failure**, and lesson 11's retries make it worse.

Lesson 11 dealt with the dependency: time out, retry carefully, stop calling it when it is clearly down.
This lesson deals with **the resource**: how much of it any one thing is allowed to use, and what to say
to work that arrives when it is gone. Three tools, one for each way the resource runs out:

| what uses up the resource | the tool |
| --- | --- |
| one slow dependency | a **bulkhead**: a cap on how much of the resource it may hold |
| one client asking too often | **throttling**: a cap on how often each client may ask |
| more work than can be done right now | a **bounded queue**, and **back pressure** when it is full |
