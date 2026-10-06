---
title: Where the logs really are
version: 1
---

`kubectl logs` feels like asking the application. **It is reading a file on the node.** The container
runtime writes everything the process prints on its standard output and error into a file per
container, under `/var/log/pods`:

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/log/pods | grep shop
default_shop-774b84ff8c-5tnl8_32daf685-6666-4ec3-b909-65de42637038
ana@laptop:~/shop$ docker exec shop-worker2 sh -c 'tail -n 2 /var/log/pods/default_shop-774b84ff8c-5tnl8_*/shop/0.log'
2026-10-06T21:38:49.667945636Z stderr F 2026-10-06T21:38:49Z GET / from 10.244.1.4:49178
2026-10-06T21:38:49.67266958Z stderr F 2026-10-06T21:38:49Z GET / from 10.244.1.4:49212
ana@laptop:~/shop$ kubectl logs shop-774b84ff8c-5tnl8 --tail=2
2026-10-06T21:38:49Z GET / from 10.244.1.4:49178
2026-10-06T21:38:49Z GET / from 10.244.1.4:49212
```

The file has each line twice-wrapped: the runtime's own timestamp, the stream (`stderr`, because the
shop logs there) and a flag, then the line exactly as the shop wrote it, which is what `kubectl logs`
returns. **The file is deleted when the pod is**, and it is rotated by size while the pod lives, so a
node keeps only recent logs of the pods it runs now.

That is why clusters run a log collector, usually as a DaemonSet from lesson 12: one pod per node
reads these files and ships the lines to a central store, where they outlive the pods and can be
searched across all of them at once. A program that writes its logs to a file inside the container
instead of to standard output is invisible to all of this.
