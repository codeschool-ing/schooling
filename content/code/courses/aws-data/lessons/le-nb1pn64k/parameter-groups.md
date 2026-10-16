---
title: Parameter groups, the configuration file you may not edit
version: 1
---

**A parameter group is the engine's configuration file, held by RDS and changed through the API.** On
the server in the cupboard, PostgreSQL reads `postgresql.conf` and MySQL reads `my.cnf`. On RDS there
is no file you can reach, so the same settings live in a named group, the instance names the group it
uses, and one group can serve many instances. Every engine version belongs to a **family**,
`postgres16` here, and a group serves only instances of its family.

**The default group cannot be changed.** Each family has one, `default.postgres16`, and an instance
created without naming a group gets it. Changing a setting then means creating a group, attaching it,
and restarting the instance, which is exactly the restart nobody wants on a busy Friday. That is why
the previous section created `quitanda-pg16` before the instance and named it at creation, empty as
it was.

## Changing two settings

`log_min_duration_statement` logs every statement that takes longer than its value in milliseconds,
which is the cheapest way to find the slow queries the first section said are still yours.
`max_connections` is the most connections the engine accepts:

```
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=log_min_duration_statement,ParameterValue=500,ApplyMethod=immediate" "ParameterName=max_connections,ParameterValue=400,ApplyMethod=pending-reboot"
{
    "DBParameterGroupName": "quitanda-pg16"
}
ana@laptop:~/aws$ aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --source user --query "Parameters[].[ParameterName,ParameterValue,ApplyMethod]" --output text
log_min_duration_statement	500	immediate
max_connections	400	pending-reboot
```

**The two `ApplyMethod`s are not a preference.** Every parameter of an engine is either **dynamic**, read
again by a running engine, or **static**, read only when it starts. PostgreSQL itself decides which:
`log_min_duration_statement` can change under a running server and `max_connections` cannot, because
the memory for each connection is laid out when the server starts. So the first can be `immediate`
and the second has to be `pending-reboot`, and on AWS asking for `immediate` on a static parameter is
refused.

What the instance says about its group is where the restart shows up:

```
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].DBParameterGroups"
[
    {
        "DBParameterGroupName": "quitanda-pg16",
        "ParameterApplyStatus": "in-sync"
    }
]
ana@laptop:~/aws$ aws rds reboot-db-instance --db-instance-identifier quitanda-orders --query DBInstance.DBInstanceStatus
"available"
```

**On AWS, that status would read `pending-reboot`**, and stay so until the instance restarted: the
group holds 400, the running engine still has the old value, and the console marks the difference.
moto says `in-sync`, because it keeps no running engine to be out of step with, and the reboot it
accepted restarted nothing. The rule to take from the real behaviour: a static parameter is a change
with a restart in it, and the restart is scheduled like any other downtime, in the maintenance window
or a quiet hour, never discovered in the next unplanned one.

## What moto does not check

```
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=no_such_setting,ParameterValue=banana,ApplyMethod=immediate"
{
    "DBParameterGroupName": "quitanda-pg16"
}
ana@laptop:~/aws$ aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --query "length(Parameters)"
3
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name default.postgres16 --parameters "ParameterName=work_mem,ParameterValue=65536,ApplyMethod=immediate"

aws: [ERROR]: An error occurred (DBParameterGroupNotFound) when calling the ModifyDBParameterGroup operation: DB Parameter Group default.postgres16 not found.
```

**moto took a parameter PostgreSQL has never had.** On AWS that request is refused, because the name
is not a parameter of the family. moto then counts three parameters in the group, the three it was
given; on AWS the same group lists every setting of the engine, hundreds of them, each with its default,
its allowed values and whether it is static.

**The third command is refused, and for the wrong reason.** On AWS `default.postgres16` exists, every
instance created without a group of its own uses it, and modifying it is refused because default groups
cannot be changed. moto has no default group at all and answers that it does not exist. The outcome
matches; the reason does not, and a student who trusted the message would learn something false. Treat
moto's parameter groups as a place to practise the commands, never as a check of the values.

## Connections are memory

**`max_connections` is the setting people raise, and the one that costs most when raised blindly.** RDS
sets it by default from the instance's memory, with a formula in the default group; for PostgreSQL the
documented default is `LEAST({DBInstanceClassMemory/9531392},5000)`, about nine hundred at most on the
8 GiB of a `db.m7g.large`, before the memory RDS keeps for itself. Each PostgreSQL connection is a
process on the server with memory of its own, so 400 busy connections can starve the cache the queries
depend on long before the limit is reached.

The fix is rarely a bigger number. It is fewer connections: a pool in the application, or **RDS Proxy**,
a managed pool in front of the instance that lets a thousand short-lived clients, such as functions
that start for each request, share a few dozen connections to the engine. Choosing between those is
the application's design, and the right column of the first section's table.

**If you installed PostgreSQL for `sql-databases` lesson 1** ("Installing PostgreSQL, and the first
conversation with it"), you can see the same settings on a real engine, which moto cannot show you.
`psql shop -c 'SHOW max_connections'` prints the value your own server started with, and the catalogue
view `pg_settings` has a column, `context`, that is PostgreSQL's own word for the difference above:
`postmaster` for a setting read only at start, `superuser` or `user` for one a running server takes.
Nothing in this lesson depends on it, and none of it was run for this lesson.
