---
title: A cluster, a primary and a read pool
version: 1
---

**An AlloyDB database is a cluster first and instances second.** The cluster is the regional
resource that owns the storage, the backups, the network it is reachable on and the password of the
`postgres` user. Instances are the machines that run the engine against that storage, and there are
exactly two kinds: one **primary**, which takes writes, and any number of **read pools**, which take
only reads. The command line has the whole vocabulary on your laptop, in its help, even though
nothing on your laptop can answer it:

```
ana@laptop:~/gcp$ gcloud alloydb instances create --help | sed -n '/^     --instance-type/,/zones in a region/p'
     --instance-type=INSTANCE_TYPE
        Specifies instance type. INSTANCE_TYPE must be one of:

         PRIMARY
            PRIMARY instances support read and write operations.
         READ_POOL
            READ_POOL instances support read operations only. Each read pool
            instance consists of one or more homogeneous nodes. * Read pool of
            size 1 can only have zonal availability. * Read pools with node
            count of 2 or more can have regional availability (nodes are
            present in 2 or more zones in a region).
```

**`PRIMARY` and `READ_POOL` are the whole list.** There is no third kind to choose, no "standby"
instance to create and no "replica" in AlloyDB's own words: the standby belongs to the primary, and
the replicas are the nodes of a read pool. The help's last two lines already say something about
availability, and the next part of this section is what they mean.

## The primary, zonal or regional

**A primary instance is one node or two, and `--availability-type` decides which.** `ZONAL` is one
node in one zone, with no automatic failover. `REGIONAL` is two nodes in two zones of the region:
the active one, which serves connections, and a standby, which serves nothing until the active one
fails. The pricing page says it plainly: "A high availability primary instance uses two nodes", and
each node is billed. Because the standby reads the same storage as the active node, a failover hands
writing over without moving data, and `gcloud alloydb instances failover` is the command that
rehearses it on purpose. Google's AlloyDB service-level agreement promises 99.99% for a regional
primary; the arithmetic of what that allows is lesson 7's, and it applies here unchanged.

**The machine is sized by its processors, and the memory follows.** The size is `--cpu-count`, and
the help says what each number means:

```
ana@laptop:~/gcp$ gcloud alloydb instances create --help | sed -n '/^     --cpu-count/,/288\./p'
     --cpu-count=CPU_COUNT
        Whole number value indicating how many vCPUs the machine should
        contain. If the instance does not have a machine-type, the vCPU count
        will be used to determine the machine type where each vCPU corresponds
        to an N2 high-mem machine:
        (https://cloud.google.com/compute/docs/general-purpose-machines#n2_machine_types).
        where CPU_COUNT can be one of: 2, 4, 8, 16, 32, 64, 96, 128. If the
        instance has a machine-type, cpu-count must have the same value as the
        vCPU count in the machine-type. Eg: if machine-type is
        c4a-highmem-4-lssd, cpu-count must be 4. CPU_COUNT must be one of: 1,
        2, 4, 8, 14, 16, 22, 32, 44, 48, 64, 72, 88, 96, 128, 144, 192, 288.
```

**An N2 high-memory machine has 8 GiB of memory per vCPU**, which is Compute Engine's definition of
that family and not something AlloyDB adds: `--cpu-count=8` is 8 vCPUs and 64 GiB. The second list
of counts, up to 288, is for the other machine series named by `--machine-type`, such as C4A, which
runs on Axion, Google's Arm processor. The pricing page prices N2 and C4A at the same rate per vCPU and per GiB,
and the last section of this lesson uses that rate.

## The read pool, one address and many nodes

**A read pool is one instance with one address and up to 20 nodes behind it.** An application
connects to the pool's address and its connections are spread across the nodes, so adding read
capacity is changing one number, `--read-pool-node-count`, rather than creating replicas and
teaching the application their names. Every node in a pool is the same size. A pool of one node can
only be zonal, as the help above says, and a pool of two or more spreads its nodes over more than one
zone, so that losing a zone leaves some of them answering.

**A cluster can have more than one pool**, and that is how Quitanda keeps its analysts from slowing
its shop. The website's catalogue pages and order history read from one pool sized for the evening
peak; the analysts' reporting tool reads from a second, larger pool of its own. Both pools read the
same storage, so neither adds a gigabyte to the bill, and a heavy report on the second never takes a
connection from the first.

## The commands, not run

**Three commands build Quitanda's orders database**: the cluster, then the primary, then the read
pool. They are shown as you would type them against a real project. **They were not run here**: there
is no AlloyDB on this laptop and no account behind this course, and their output is therefore not
shown.

```sh
gcloud alloydb clusters create quitanda-orders --region=southamerica-east1 \
  --network=default --password="$ALLOYDB_PASSWORD" --database-version=POSTGRES_16 \
  --enable-continuous-backup --continuous-backup-recovery-window-days=14
gcloud alloydb instances create quitanda-orders-primary --cluster=quitanda-orders \
  --region=southamerica-east1 --instance-type=PRIMARY --cpu-count=8 --availability-type=REGIONAL
gcloud alloydb instances create quitanda-orders-reads --cluster=quitanda-orders \
  --region=southamerica-east1 --instance-type=READ_POOL --cpu-count=8 --read-pool-node-count=2
```

**`--network` names a VPC network, and the instances get private addresses in it.** An AlloyDB
instance is reached from inside the network by default, which needs the network's private services
access set up first, the subject of `gcp-foundations`; a public address is an option to turn on,
not the default. The password comes from a variable so that it is not left in your shell history.
`POSTGRES_16` is one of the versions the help offers, alongside 14, 15, 17 and 18.

**Continuous backup is what point-in-time recovery stands on.** With it on, AlloyDB keeps the log
for the recovery window, here fourteen days, and can restore the cluster to any moment inside it as a
new cluster, the same idea as lesson 7's point-in-time recovery for Cloud SQL. Its storage is billed
at the backup rate on the pricing page, which the last section of this lesson lists and leaves out of its totals.

**The flags are real even though the calls are not.** Every flag in those three commands appears in
`gcloud alloydb … --help` on this laptop, which is the check that can be made without an account,
because the command line refuses a flag it does not know before it sends anything:

```
ana@laptop:~/gcp$ gcloud alloydb instances create quitanda-orders-reads --cluster=quitanda-orders --region=southamerica-east1 --instance-type=READ_POOL --cpu-count=8 --read-pool-nodes=2
ERROR: (gcloud.alloydb.instances.create) unrecognized arguments: --read-pool-nodes=2 (did you mean '--read-pool-node-count'?) 

To search the help text of gcloud commands, run:
  gcloud help -- SEARCH_TERMS
```

**`--read-pool-nodes` is not a flag**, and the refusal names the one that is. What it cannot check is
anything Google would answer, whether `southamerica-east1` has capacity for the machine today, or
whether the network has private services access, and those are the errors a first real attempt
usually meets.
