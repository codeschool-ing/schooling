---
title: Maintenance windows, and the channels that fill them
version: 1
---

A maintenance window looks like a switch that turns automatic upgrades on, and it is not one.
Microsoft's documentation says it in one sentence: planned maintenance schedules the timing of
automatic upgrades, and enabling or disabling it does not enable or disable them. **Two settings
decide what happens to a cluster on its own: a channel says what to upgrade to, and a window says
when.** A window with no channel behind it is an appointment nobody keeps.

## The two channels

`aks.bicep` set both in `autoUpgradeProfile`. The first, `upgradeChannel`, moves the Kubernetes
version, and the documentation gives five values for AKS Standard:

| `upgradeChannel` | what it upgrades to |
|---|---|
| `none` | nothing; the default when you leave it unset |
| `patch` | the latest patch of the minor version the cluster already runs |
| `stable` | the latest patch of minor version N-1, one behind the newest |
| `rapid` | the latest patch of the newest minor version, by way of N-1 if the cluster is on N-2 |
| `node-image` | node images only; legacy, and Microsoft says not to use it |

Put the shop's versions in. Say the cluster runs 1.36.2, and 1.36.6, 1.37.1 and 1.37.3 are
available. `patch` moves it to 1.36.6. `stable` also moves it to 1.36.6, because 1.36 is N-1 while
1.37 is the newest. `rapid` moves it to 1.37.3. **`stable` is the channel that keeps a cluster
inside N-2 without making it the first to run a new minor version**, which is why `aks.bicep`
chose it. An automatic upgrade is the manual one done for you: control plane first, then each pool
in turn, with each pool's surge and drain settings from the previous section. It always moves the
whole cluster, so with a channel set, `--control-plane-only` is refused.

The second, `nodeOSUpgradeChannel`, moves the node images and never the Kubernetes version:

| `nodeOSUpgradeChannel` | what reaches the nodes |
|---|---|
| `None` | nothing; patching is yours |
| `Unmanaged` | the operating system's own updates, applied on the node by its own tools, about once a day on Ubuntu and Azure Linux |
| `SecurityPatch` | security patches tested by AKS, reimaging a node only when a patch needs it |
| `NodeImage` | a new node image every week, each node reimaged, surge and drain as before |

`NodeImage` has been the default for a new AKS Standard cluster since API version `2023-06-01`.
Either channel takes up to 24 hours to act on a change, by the documentation's account.

## The three windows

A cluster can carry three maintenance configurations, each a child resource with a fixed name:

| name | what it schedules |
|---|---|
| `default` | AKS's weekly releases: the control plane's own components and the system add-ons |
| `aksManagedAutoUpgradeSchedule` | the upgrades the `upgradeChannel` decides on |
| `aksManagedNodeOSUpgradeSchedule` | the node images the `nodeOSUpgradeChannel` decides on |

Each window is a schedule, a start time, a duration and an offset from UTC. The schedule is `Weekly`,
`AbsoluteMonthly` (a day of the month), `RelativeMonthly` (the last Monday, say) or `Daily`, and
`default` takes only `Weekly`. `utcOffset` defaults to `+00:00`, so a window written without it
starts at the time you typed in UTC, which for São Paulo is three hours early. The documentation
asks for at least four hours when auto-upgrade uses the window, and `notAllowedDates` blocks out a
range of dates, such as the week of Black Friday for a shop.

What a window does not promise matters as much. **Maintenance is best effort, and the window bounds
when work starts, not when it ends**: an upgrade begun at 11:50 in a window that closes at 12:00 runs
to completion, and nothing new starts after 12:00. Microsoft may break any window, even a
`notAllowedDates` range, for urgent maintenance. A platform-initiated upgrade, from the previous
section, ignores the windows. And a window that was just created or changed needs 15 minutes before
its start time to be taken into account, and a cluster that is running when it opens.

## The shop's windows, in Bicep

The shop sells least in the early hours of Sunday, and the early hours of Wednesday are quiet
enough for node images. A maintenance configuration is a child of the cluster, so this file declares the cluster as
`existing`, which names it without creating or changing it. Save it as `maintenance.bicep`:

```bicep
// maintenance.bicep
resource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' existing = {
  name: 'shop-aks'
}

resource upgrades 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-01-01' = {
  parent: aks
  name: 'aksManagedAutoUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Sunday'
        }
      }
      durationHours: 4
      utcOffset: '-03:00'
      startTime: '02:00'
    }
  }
}

resource nodeImages 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-01-01' = {
  parent: aks
  name: 'aksManagedNodeOSUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Wednesday'
        }
      }
      durationHours: 4
      utcOffset: '-03:00'
      startTime: '01:00'
    }
  }
}
```

Kubernetes upgrades from 02:00 to 06:00 on Sundays in São Paulo, which is 05:00 to 09:00 UTC, and
node images from 01:00 on Wednesdays. The weekly cadence for node images follows Microsoft's advice
for the `NodeImage` channel, since a new image ships every week. It compiles cleanly:

```
ana@laptop:~/azure$ bicep build maintenance.bicep
ana@laptop:~/azure$ jq -c '.resources[] | .properties.maintenanceWindow | [.schedule.weekly.dayOfWeek, .startTime, .utcOffset, .durationHours]' maintenance.json
["Sunday","02:00","-03:00",4]
["Wednesday","01:00","-03:00",4]
```

Now the three slips that come naturally when writing one by hand: a two-hour window, the offset
without its leading zero, and the day abbreviated.

```
ana@laptop:~/azure$ sed -e 's/durationHours: 4/durationHours: 2/' -e "s/'-03:00'/'-3:00'/" -e "s/'Sunday'/'Sun'/" maintenance.bicep > slips.bicep
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(17,22) : Warning BCP328: The provided value (which will always be less than or equal to 2) is too small to assign to a target for which the minimum allowable value is 4. [https://aka.ms/bicep/core-diagnostics#BCP328]
/home/ana/azure/slips.bicep(18,18) : Warning BCP416: The supplied string does not match the expected pattern of /$^(-|\+)[0-9]{2}:[0-9]{2}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
/home/ana/azure/slips.bicep(35,22) : Warning BCP328: The provided value (which will always be less than or equal to 2) is too small to assign to a target for which the minimum allowable value is 4. [https://aka.ms/bicep/core-diagnostics#BCP328]
/home/ana/azure/slips.bicep(36,18) : Warning BCP416: The supplied string does not match the expected pattern of /$^(-|\+)[0-9]{2}:[0-9]{2}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
```

Two of the three were caught, once for each window. `durationHours` has a minimum of 4 in the type,
and `utcOffset` carries the pattern of a sign and two digits each side of the colon. The day passed
in silence, because the type of `dayOfWeek` is any string at all: the seven names are the service's rule.

On a subscription, the command line writes the same windows; this was not run:

```sh
az aks maintenanceconfiguration add --resource-group shop --cluster-name shop-aks --name aksManagedAutoUpgradeSchedule --schedule-type Weekly --day-of-week Sunday --interval-weeks 1 --duration 4 --utc-offset -03:00 --start-time 02:00
```

Its help states the range of `--duration`, and agrees with the compiler's minimum:

```
ana@laptop:~/azure$ az aks maintenanceconfiguration add --help | grep -m1 -- "--duration"
    --duration                     : The length of maintenance window range from 4 to 24 hours.
Exception ignored in: <_io.TextIOWrapper name='<stdout>' mode='w' encoding='utf-8'>
BrokenPipeError: [Errno 32] Broken pipe
```

The windows are the last decision AKS leaves to you about its own machinery. Lesson 12 is about
AKS Automatic, which takes most of the decisions in this lesson out of your hands, including the
channels, and is worth reading against them.
