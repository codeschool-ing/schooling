---
title: YARN
version: 1
---

**YARN, Yet Another Resource Negotiator, is a cluster manager that knows nothing about MapReduce or
Spark.** A *ResourceManager* keeps the list of machines and decides who gets what. A *NodeManager* on
each machine reports what it has and starts *containers*, a process with a fixed amount of memory and
cores, when told to. Each application runs an *ApplicationMaster* in its first container, which asks
the ResourceManager for more containers and runs its tasks in them. The roles are lesson 2's, with
different names: the ResourceManager is the standalone master, the NodeManager the worker, and the
ApplicationMaster is where a Spark driver lives in cluster mode.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" data-fig=\"l12-yarn\" aria-label=\"YARN's roles. A client submits an application to the ResourceManager. The ResourceManager tells a NodeManager to start the application's first container, its ApplicationMaster, which then asks the ResourceManager for more containers and runs its tasks in them, on the NodeManagers of other machines.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">client</text><rect x=\"280.0\" y=\"24.0\" width=\"180.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ResourceManager</text><text x=\"370.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">machines, queues</text><path d=\"M140.0 55.0 L278.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"209.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 submit</text><rect x=\"40.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"54.0\" y=\"172.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ApplicationMaster</text><rect x=\"270.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"284.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">task</text><rect x=\"374.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">task</text><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NodeManager</text><rect x=\"514.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">task</text><rect x=\"604.0\" y=\"180.0\" width=\"82.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">task</text><path d=\"M200.0 140.0 L300.0 86.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"236.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 ask for containers</text><path d=\"M140 260 L140 284 L600 284\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M370.0 284.0 L370.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><path d=\"M600.0 284.0 L600.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"484.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 start tasks</text></svg>", "caption": "The ResourceManager decides; each application's own ApplicationMaster asks and runs its tasks."}
```

Hadoop 3.5.0, installed in lesson 3, already contains YARN. Its configuration is three files in
`$HADOOP_HOME/etc/hadoop`, and a script of this lesson writes them and starts the two processes. Save
it as `~/big/yarn.sh`:

```schooling-example
{
  "language": "sh",
  "file": "yarn.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# A ResourceManager and one NodeManager on this machine, with two queues.\n#   sh yarn.sh setup    write the configuration (once)\n#   sh yarn.sh start    start the two processes\n#   sh yarn.sh stop     stop them\nset -e\nCONF=$HADOOP_HOME/etc/hadoop\n\n"
    },
    {
      "code": "yarn_site() {\n  cat <<END\n<configuration>\n  <property><name>yarn.resourcemanager.hostname</name><value>localhost</value></property>\n  <property><name>yarn.nodemanager.resource.memory-mb</name><value>6144</value></property>\n  <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>4</value></property>\n  <property><name>yarn.scheduler.minimum-allocation-mb</name><value>256</value></property>\n  <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>\n  <property><name>yarn.log-aggregation-enable</name><value>true</value></property>\n  <property><name>yarn.nodemanager.vmem-check-enabled</name><value>false</value></property>\n  <property><name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name><value>98</value></property>\n  <property><name>yarn.nodemanager.env-whitelist</name><value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value></property>\n</configuration>\nEND\n}\n\n",
      "note": "**The NodeManager offers 6 GB and 4 cores** of this machine to YARN, which is only safe with the standalone cluster stopped, and YARN hands them out in containers of at least 256 MB. The auxiliary service is the shuffle of MapReduce, which runs inside the NodeManager. Log aggregation copies each finished container's logs to HDFS, where `yarn logs` finds them. The virtual memory check is off because Java 17 reserves far more address space than it uses, and the check would kill containers that are well within their memory. And a NodeManager declares itself unhealthy, and runs nothing, when its disk is more than 90% full; the machine this was recorded on was past that, so the line after raises it to 98%."
    },
    {
      "code": "mapred_site() {\n  cat <<END\n<configuration>\n  <property><name>mapreduce.framework.name</name><value>yarn</value></property>\n  <property><name>mapreduce.application.classpath</name><value>\\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:\\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value></property>\n  <property><name>yarn.app.mapreduce.am.resource.memory-mb</name><value>512</value></property>\n  <property><name>mapreduce.map.memory.mb</name><value>512</value></property>\n  <property><name>mapreduce.reduce.memory.mb</name><value>512</value></property>\n</configuration>\nEND\n}\n\n",
      "note": "**MapReduce is told to run on YARN** instead of the local runner, where to find its own classes inside a container, and how much memory its containers ask for."
    },
    {
      "code": "capacity_scheduler() {\n  cat <<END\n<configuration>\n  <property><name>yarn.scheduler.capacity.root.queues</name><value>nightly,analysts</value></property>\n  <property><name>yarn.scheduler.capacity.root.nightly.capacity</name><value>70</value></property>\n  <property><name>yarn.scheduler.capacity.root.nightly.maximum-capacity</name><value>70</value></property>\n  <property><name>yarn.scheduler.capacity.root.analysts.capacity</name><value>30</value></property>\n  <property><name>yarn.scheduler.capacity.root.analysts.maximum-capacity</name><value>30</value></property>\n  <property><name>yarn.scheduler.capacity.maximum-am-resource-percent</name><value>0.5</value></property>\n</configuration>\nEND\n}\n\ncase \"$1\" in\n  setup)\n    yarn_site > $CONF/yarn-site.xml\n    mapred_site > $CONF/mapred-site.xml\n    capacity_scheduler > $CONF/capacity-scheduler.xml ;;\n  start)\n    yarn --daemon start resourcemanager\n    yarn --daemon start nodemanager ;;\n  stop)\n    yarn --daemon stop nodemanager\n    yarn --daemon stop resourcemanager ;;\nesac\n",
      "note": "**Two queues under the root**: `nightly` with 70% of the cluster and `analysts` with 30%. `maximum-capacity` caps `nightly` at its share, so however much it asks for, the analysts' 30% is free when they need it. A cluster with preemption lets the big queue borrow the idle share and takes it back by killing containers; this one keeps it simple."
    }
  ]
}
```

Write the configuration once, start YARN, and ask it what it has:

```
ana@lab:~/big$ sh yarn.sh setup
ana@lab:~/big$ sh yarn.sh start
ana@lab:~/big$ yarn node -list 2>/dev/null
Total Nodes:1
         Node-Id	     Node-State	Node-Http-Address	Number-of-Running-Containers
       lab:38703	        RUNNING	         lab:8042	                           0
ana@lab:~/big$ mapred queue -list 2>/dev/null
======================
Queue Name : nightly 
Queue State : running 
Scheduling Info : Capacity: 70.0, MaximumCapacity: 70.0, CurrentCapacity: 0.0 
======================
Queue Name : analysts 
Queue State : running 
Scheduling Info : Capacity: 30.000002, MaximumCapacity: 30.000002, CurrentCapacity: 0.0 
```

**One NodeManager with 6,144 MB and 4 cores, and two queues sharing it 70 and 30.** The queues are
lesson 2's promise: the analysts keep 30% however much the nightly load asks for. `CurrentCapacity`
is how much of its share each queue is using, nothing yet. The ResourceManager also answers on port
8088, for a browser and, under `/ws/v1/cluster`, as JSON.
