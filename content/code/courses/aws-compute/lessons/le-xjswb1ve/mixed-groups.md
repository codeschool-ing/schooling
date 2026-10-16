---
title: A group that is part on demand and part spot
version: 1
---

The wrong way to use spot is to change one instance to spot and hope. **The right unit is a group
that holds a fixed floor of on-demand instances and fills the rest with spot, across several
instance types**, so that an interruption costs a fraction of the capacity and the group replaces
it from whichever pool still has room. An auto scaling group does all of that from one setting, the
mixed instances policy.

## The policy

It has two halves: which instance types the group may launch, and how it divides them between
on demand and spot. **Copy it with the button and save it as `~/aws/mixed.json`.**

```schooling-example
{"language": "json", "file": "mixed.json", "parts": [{"code": "{\n  \"LaunchTemplate\": {\n    \"LaunchTemplateSpecification\": {\"LaunchTemplateName\": \"workers\", \"Version\": \"$Default\"},\n", "note": "The template every instance comes from, whatever its type, purchased either way. The image, the disk and the tags are the same for all of them; only the type and the price change."}, {"code": "    \"Overrides\": [\n      {\"InstanceType\": \"m7i.large\"},\n      {\"InstanceType\": \"m6i.large\"},\n      {\"InstanceType\": \"m6a.large\"},\n      {\"InstanceType\": \"m5.large\"}\n    ]\n  },\n", "note": "Four types of the same shape, 2 vCPUs and 8 GiB each, from three generations and two processor makers. Each one is a separate pool of spare capacity, and four pools are four chances that one of them has room when another does not."}, {"code": "  \"InstancesDistribution\": {\n    \"OnDemandBaseCapacity\": 2,\n    \"OnDemandPercentageAboveBaseCapacity\": 25,\n", "note": "The first two instances are always on demand, and above them a quarter are on demand and three quarters are spot. The base is the part of the group that an interruption can never take."}, {"code": "    \"SpotAllocationStrategy\": \"price-capacity-optimized\"\n  }\n}\n", "note": "How AWS picks among the four pools for each spot instance: the pools least likely to be interrupted, and among those the cheapest. AWS recommends it for most workloads."}]}
```

The types are the decision people get wrong most often, and the wrong version is one type. **Every
type in every zone is a separate pool of spare capacity**, and AWS interrupts by pool. A group that
allows one type in three zones draws on three pools; this one draws on twelve. The types should be
interchangeable for the application: the same vCPUs and memory, the same processor architecture.
An Arm type such as `m7g.large` can join, but only with its own launch template override naming an
`arm64` image, because one image does not boot on both.

## The arithmetic of the distribution

With a desired capacity of ten, the base takes the first two on demand. The remaining eight are
split by the percentage: 25% of eight is two more on demand, and the other six are spot. **Four on
demand and six on spot**, and the four are the floor an interruption cannot touch. As the group
grows, the base stays at two and the split applies to everything above it: at thirty, it is two
plus 25% of twenty-eight, so nine on demand and twenty-one on spot.

The allocation strategy chooses the pool for each spot instance:

| strategy | what it picks |
| --- | --- |
| `price-capacity-optimized` | the pools least likely to be interrupted, and the cheapest of those; AWS's recommendation |
| `capacity-optimized` | the pools least likely to be interrupted, whatever the price |
| `lowest-price` | the cheapest pools, which are often the ones most likely to be taken back |

## The group in moto

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name workers --launch-template-data '{"ImageId": "ami-0629d059c178d0eac", "InstanceType": "m7i.large"}' --query LaunchTemplate.LaunchTemplateId --output text
lt-402d88ea28bddd6cd
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'join(`,`, Subnets[].SubnetId)' --output text)
ana@laptop:~/aws$ aws autoscaling create-auto-scaling-group --auto-scaling-group-name workers --min-size 0 --max-size 20 --desired-capacity 10 --vpc-zone-identifier "$SUBNETS" --capacity-rebalance --mixed-instances-policy file://mixed.json
```

`--capacity-rebalance` is the group's answer to the rebalance recommendation of the previous
section: on AWS, when one of its spot instances receives one, the group launches a replacement
first, in a pool at lower risk, and only then terminates the instance at risk. Here is what moto
made of the whole request:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names workers --query "AutoScalingGroups[].{rebalance: CapacityRebalance, distribution: MixedInstancesPolicy.InstancesDistribution, types: MixedInstancesPolicy.LaunchTemplate.Overrides[].InstanceType}"
[
    {
        "rebalance": true,
        "distribution": {
            "OnDemandBaseCapacity": 2,
            "OnDemandPercentageAboveBaseCapacity": 25,
            "SpotAllocationStrategy": "price-capacity-optimized"
        },
        "types": [
            "m7i.large",
            "m6i.large",
            "m6a.large",
            "m5.large"
        ]
    }
]
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=workers --query "Reservations[].Instances[].[InstanceType,InstanceLifecycle]" --output text | sort | uniq -c
     10 m7i.large	None
```

**The description is faithful and the instances are not.** moto stored the distribution, the four
types and capacity rebalancing exactly as sent. Then it launched ten `m7i.large`, all of them on
demand: `None` in the lifecycle column means not spot. On AWS this group would hold four on-demand
instances and six spot ones, spread over the four types and the three zones. The policy can be
written and read back in this lab, and its effect is AWS's documented behaviour.

## Holding an instance while it drains

The two minutes of an interruption are short, and a group terminating an instance for a scale-in or
a rebalance can give it longer. A **lifecycle hook** on termination holds a leaving instance in a
waiting state until it says it is done, or until the hook's timeout runs out:

```
ana@laptop:~/aws$ aws autoscaling put-lifecycle-hook --auto-scaling-group-name workers --lifecycle-hook-name drain --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING --heartbeat-timeout 120 --default-result CONTINUE
ana@laptop:~/aws$ aws autoscaling describe-lifecycle-hooks --auto-scaling-group-name workers
{
    "LifecycleHooks": [
        {
            "LifecycleHookName": "drain",
            "AutoScalingGroupName": "workers",
            "LifecycleTransition": "autoscaling:EC2_INSTANCE_TERMINATING",
            "NotificationTargetARN": "arn:aws:sqs:us-east-1:123456789012:my-queue",
            "RoleARN": "arn:aws:iam::1234567890:role/my-auto-scaling-role",
            "HeartbeatTimeout": 120,
            "GlobalTimeout": 172800,
            "DefaultResult": "CONTINUE"
        }
    ]
}
```

The hook is stored with a timeout of 120 seconds and the default result `CONTINUE`, which means the
termination goes ahead when the time is up. **The two ARNs in it are moto inventing values nobody
gave**: a queue in `us-east-1` and a role in an account numbered `1234567890`. On AWS a hook created
without a notification target has none, and the instance's own drain script calls
`complete-lifecycle-action` when it is finished. A hook does not lengthen a spot interruption: when
AWS takes the capacity back, two minutes is all there is.
