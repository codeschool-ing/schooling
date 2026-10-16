---
title: The one service in this course that moto does not have
version: 1
---

**moto 5.2.3 has no MWAA at all.** Every other service in this course answers in the lab, however
little it does behind the answer; this one does not answer, and the way it fails to answer is worth
reading closely, because the error names the wrong culprit. Ask for the environments:

```
ana@laptop:~/aws$ aws mwaa list-environments

aws: [ERROR]: Could not connect to the endpoint URL: "http://api.localhost:4567/environments"
ana@laptop:~/aws$ AWS_ENDPOINT_URL=http://127.0.0.1:4567 aws mwaa list-environments

aws: [ERROR]: Could not connect to the endpoint URL: "http://api.127.0.0.1:4567/environments"
ana@laptop:~/aws$ aws mwaa list-environments --debug 2>&1 | grep -o "'host_prefix': '[^']*'"
'host_prefix': 'api.'
ana@laptop:~/aws$ getent hosts api.localhost; echo "exit $?"
exit 2
```

**The command line did not ask `localhost` at all; it asked `api.localhost`.** The first error names
an address nobody configured. The second command proves it is the command line's doing: with the
endpoint given as an IP address, it asked `api.127.0.0.1`, which is not even a valid name. The third
shows why. AWS's description of the MWAA API, which the command line is built from, says that these
calls go to a **host prefix**, `api.`, put in front of whatever host the endpoint names. Against AWS
that turns `airflow.sa-east-1.amazonaws.com` into `api.airflow.sa-east-1.amazonaws.com`, a real
address. Against moto it turns `localhost` into a name the last command shows this machine cannot
resolve.

## What your machine shows depends on its resolver

**Some resolvers answer every name ending in `.localhost` with the loopback address**, as the
standard for that name says they may, and Ubuntu's own does. On such a machine the request reaches
moto, and moto has nothing to give it:

```
ana@laptop:~/aws$ getent hosts api.localhost
127.0.0.1       api.localhost
ana@laptop:~/aws$ aws mwaa list-environments

aws: [ERROR]: An error occurred (500) when calling the ListEnvironments operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/environments
404
```

**Now the name resolves, the request arrives, and moto answers `500`**, an error from inside the
server; asked directly for the same path, it says `404`, no such thing. Either way the conclusion is
the one the first transcript already reached by a different road: there is no MWAA here to talk to.
On the machine this course was recorded on, the name does not resolve, so the second transcript was
made by adding that one name to the machine's hosts file inside the recording, and it is what a
student whose resolver answers will see.

**Do not "fix" it by sending `api.localhost` somewhere.** Pointing the name at moto, as the second
transcript does, gets you a server with no MWAA in it; the only fix is a server that has one, and
none of this course's lab does. Nothing that follows in this lesson needs it: the DAG folder is S3,
which moto has, and the alternative to MWAA in the last two sections is two services moto stores
faithfully.

## What this lesson cannot show you, then

**Everything that is MWAA's own was not run here**: creating an environment, which on AWS takes long
enough that people go and do something else; the scheduler picking up `nightly_orders.py` from the
bucket; a worker starting the Glue job; the web server; the logs in CloudWatch. All of it is
taught from AWS's documented behaviour. What the lab does show is the two things that decide whether
MWAA is worth its price, which are what the environment costs while it waits, in the next section,
and what the same pipeline looks like without it, in the two after.
