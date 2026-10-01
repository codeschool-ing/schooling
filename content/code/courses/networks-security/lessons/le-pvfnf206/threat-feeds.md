---
title: Threat intelligence feeds
version: 1
---

Lesson 2 listed **threat intelligence feeds** among what a next-generation firewall adds: lists of
addresses, domain names and file hashes that somebody has seen misbehaving, published for others to
block. They come from commercial vendors, from national response teams, and from open projects. What
arrives is a file, and this is the lab's:

```
root@admin:~# cat feed.txt
# example-intel.org list, 2026-09-28, addresses seen scanning for exposed secrets
203.0.113.50
198.51.100.23
198.51.100.140
```

A feed is only as good as its date and its reason. This one says who published it, when, and what
the addresses were doing. A list without those is a list nobody can review.

**The first use is looking back.** Before blocking anything, the question worth asking is whether any
of these addresses already talked to us. The collection on `admin` answers it:

```
root@admin:~# grep -v '^#' feed.txt | while read a; do jq -r --arg a $a 'select(.src_ip == $a) | .src_ip' /var/log/lab/remote/fw/flows.json /var/log/lab/remote/fw/drops.json; done | sort | uniq -c
      6 203.0.113.50
```

Six records from `203.0.113.50`: the two flows and four drops from earlier. The other two addresses
never appeared. That look back, run over months of flow records, is often how an intrusion is found:
an address named today in somebody else's report turns out to have visited in July.

**The second use is blocking.** The feed goes into a set whose elements expire, and a rule at the top
of the forward chain drops and logs anything from it:

```
root@fw:~# nft add set ip filter intel "{ type ipv4_addr; flags timeout; timeout 1d; }"
root@fw:~# nft 'insert rule ip filter forward ip saddr @intel log group 1 prefix "intel-drop" drop'
root@fw:~# nft add element ip filter intel "{ 203.0.113.50, 198.51.100.23, 198.51.100.140 }"
root@fw:~# nft list set ip filter intel
table ip filter {
	set intel {
		type ipv4_addr
		timeout 1d
		elements = { 198.51.100.23 expires 23h59m59s968ms, 198.51.100.140 expires 23h59m59s968ms,
			     203.0.113.50 expires 23h59m59s968ms }
	}
}
```

`timeout 1d` is not a detail. An address in a feed today may belong to somebody else next month:
cloud addresses are reassigned, and one shared address can front a whole mobile network. An entry that
is refreshed while the feed still lists it, and falls out when it stops, keeps the block from
outliving its reason.

`remote` is now refused, and `branch`, on the same internet segment and not on the list, is not:

```
ana@remote:~$ curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/
000
ana@branch:~$ curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
```

The refusals carry their own prefix, so a report can tell them apart from the policy's:

```
root@admin:~# tail -3 /var/log/lab/remote/fw/drops.json | jq -c '[.src_ip, .dest_port, ."oob.prefix"]'
["203.0.113.50",80,"intel-drop"]
["203.0.113.50",80,"intel-drop"]
["203.0.113.50",80,"intel-drop"]
```

Two cautions. **A feed is somebody else's judgement**, so its blocks deserve the same review as the
firewall's own rules, and a customer who cannot reach the shop because of a feed is a real cost. And
**a feed rule placed first sees everything**, including replies to connections that started inside;
that is usually what is wanted, and it should be decided rather than discovered.
