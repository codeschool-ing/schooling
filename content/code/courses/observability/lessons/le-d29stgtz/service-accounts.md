---
title: An account for a robot
version: 1
---

Scripts talk to Grafana too: a deploy pipeline that marks each release on the dashboards, a job that
backs dashboards up, a tool that provisions folders. **None of them should hold the admin password.**
Grafana's answer is a **service account**: an identity for a program, with a role, and tokens that
can be revoked one at a time. One is created for the deploy pipeline, with the `Editor` role, and
given a token:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d '{"name": "deploy-bot", "role": "Editor"}' localhost:3000/api/serviceaccounts | jq -c '{id, name, role}'
{"id":2,"name":"deploy-bot","role":"Editor"}
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d '{"name": "annotations"}' localhost:3000/api/serviceaccounts/2/tokens | jq -r .key > .grafana-token && wc -c < .grafana-token
47
```

The token went straight into a file, 47 bytes counting its newline, and never onto the screen. With it, the robot
can read what an editor can read, and it cannot delete a data source, which only an administrator
may:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/search
200
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" -X DELETE localhost:3000/api/datasources/uid/prometheus
403
```

**200 for the search, 403 for the delete.** That refusal is the point of the exercise: a token that
leaks from a pipeline's logs can annotate and edit dashboards, and it cannot remove the data sources
every dashboard depends on. Every call from here to the end of the lesson uses the token instead of
the password, which is the habit worth copying: **the admin password is for setting things up, and a
token with the smallest role that works is for everything automated**.
