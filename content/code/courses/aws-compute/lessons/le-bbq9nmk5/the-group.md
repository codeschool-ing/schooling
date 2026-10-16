---
title: "The group: three numbers and a template"
version: 1
---

An auto scaling group is usually introduced as the thing that adds servers when traffic rises.
Adding servers is something a group does with a number that happens to move. **A group is a control loop over a count**: it holds a
number of instances, compares it with the instances that exist, and launches or terminates until
the two agree. It keeps doing that whether the number moves or not, and when nothing is scaling it
is still replacing whatever fails.

## What a group is made of

Three numbers, a template and a list of subnets.

- **The minimum** is the fewest instances the group will run, whatever any policy says.
- **The maximum** is the most, and it is a ceiling on the bill as much as on capacity.
- **The desired capacity** is the number the group is working towards now. It has to sit between
  the other two, and it is the one number that scaling policies move (lesson 5).

The template says what each instance is, and the subnets say where instances may go. A subnet
lives in one Availability Zone, so the list of subnets is also the list of zones the group can
use. Ana takes every subnet of moto's default VPC, one per zone of São Paulo, joins their ids with
commas, and creates the group:

```
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ echo "$SUBNETS"
subnet-a320d80c3247aca2b,subnet-fec45bdedb73af5bf,subnet-0f090c6c9427312e3
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name web --launch-template 'LaunchTemplateName=web,Version=$Default' --min-size 2 --max-size 6 --desired-capacity 3 --vpc-zone-identifier "$SUBNETS"
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{min: MinSize, max: MaxSize, desired: DesiredCapacity, template: LaunchTemplate.Version, zones: AvailabilityZones}"
[
    {
        "min": 2,
        "max": 6,
        "desired": 3,
        "template": "$Default",
        "zones": [
            "sa-east-1a",
            "sa-east-1b",
            "sa-east-1c"
        ]
    }
]
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,LifecycleState,HealthStatus,LaunchTemplate.Version]" --output table
------------------------------------------------------
|            DescribeAutoScalingInstances            |
+----------------------+-------------+----------+----+
|  i-b96143049d6fcbfd7 |  InService  |  Healthy |  1 |
|  i-1c9f5ffde740488e8 |  InService  |  Healthy |  1 |
|  i-c6669b95cfcc5be41 |  InService  |  Healthy |  1 |
+----------------------+-------------+----------+----+
```

`create-auto-scaling-group` prints nothing when it works. The description shows the three numbers
and the three zones the group worked out from the subnets. **The template is still `$Default`
there, but every instance records a number.** The name is resolved at the moment of each launch,
and the version an instance came from is a fact about it from then on. That is why the last
section of this lesson has work to do.

## How the group marks its instances

An instance launched by a group carries the tags of its template version, and three more that
AWS writes itself:

```
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web --query "Reservations[0].Instances[0].Tags" --output table
-----------------------------------------------------------
|                    DescribeInstances                    |
+--------------------------------+------------------------+
|               Key              |         Value          |
+--------------------------------+------------------------+
|  app                           |  shop                  |
|  aws:ec2launchtemplate:id      |  lt-420bf22b86d1ab21b  |
|  aws:ec2launchtemplate:version |  1                     |
|  aws:autoscaling:groupName     |  web                   |
+--------------------------------+------------------------+
```

The `aws:` prefix is reserved: nobody can write those tags, so they are a reliable way back from
an instance to its group and its template version. **`aws:autoscaling:groupName` is the filter
for "the instances of this group"**, because their ids are chosen by the group and change every
time one is replaced. The commands in the next section use it.

## Moving the desired capacity by hand

A policy moves the desired capacity, and so can a person. `set-desired-capacity` is the manual
lever, and the group launches or terminates to match:

```
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 5
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[DesiredCapacity,length(Instances)]" --output text
5	5
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 8
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[MaxSize,DesiredCapacity,length(Instances)]" --output text
6	8	8
ana@laptop:~/aws$ aws autoscaling set-desired-capacity --auto-scaling-group-name web --desired-capacity 3
```

Five went to five. **Eight went to eight on a group whose maximum is six, and that is moto
accepting what AWS refuses.** On AWS the same call fails with a `ValidationError`, because the
desired capacity must lie between the minimum and the maximum, and nothing is launched. moto
checks neither bound. Its count of eight is a record nobody pays for; on AWS, a maximum that could
be overrun would not be a ceiling on the bill at all. Ana sets it back to three.

## Which instances go when the number falls

When the desired capacity drops, the group has to choose who to terminate, and on AWS the
**default termination policy** chooses, for a group of one instance type, in a documented order:

1. the zone with the most instances, so the group stays balanced across zones;
2. within it, instances launched from the oldest launch template or configuration;
3. then the instance closest to its next billing hour;
4. and at random between whatever is left.

The second step is what makes a smaller group tidy up after a change: instances on old versions
go first. Other policies exist (`OldestInstance`, `NewestInstance`, `OldestLaunchTemplate`), and
a group can name several in order.

An instance doing something that must not be cut short, such as a long job, can be protected:
**scale-in protection** (`set-instance-protection`) takes it out of the choice when the count
falls. It does not protect it from a failed health check, which is the next section's subject.
And for the instance that is chosen, a **lifecycle hook** can hold it in a waiting state for a few
minutes, so it can finish its requests before it goes. Lesson 6 uses one to drain a spot instance.

## Two settings that change what a group is

A group with minimum, desired and maximum all at 1 never scales, and is still worth having: it
replaces its one instance when that instance fails. For a single server that must come back on
its own, it is the cheapest arrangement AWS offers, provided nothing on that server needs to
survive it.

A group with minimum 0 can be emptied completely, by hand or by a schedule (lesson 5), and costs
nothing for its instances while it is empty. What it keeps costing is whatever does not belong to
the instances: a load balancer in front of it bills by the hour whether or not there are instances
behind it.
