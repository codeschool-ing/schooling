---
title: Tuning without going blind
version: 1
---

A new detection deployment produces too many alerts, and the temptation is to delete the rules that
fire most. **That removes the noise and the signal together.** Tuning is the discipline of silencing
exactly what is understood and nothing else.

Here, the branch office's router runs a monitoring check that logs in to the shop repeatedly, and the
counting rule fires on it every few minutes. The check is known and legitimate, so the rule is told to
ignore that one source, in the engine's threshold file rather than in the rule:

```
root@sensor:~# cat /etc/suricata/threshold.config
suppress gen_id 1, sig_id 1000201, track by_src, ip 203.0.113.70
```

`suppress` for signature 1000201, when the source is `203.0.113.70`. Every other source still counts.
A signal reloads the rules without stopping the engine:

```
root@sensor:~# kill -USR2 $(cat /var/log/suricata/suricata.pid); sleep 6; grep -c "rule reload complete" /var/log/suricata/suricata.log
1
```

Then the branch posts the form fifteen times, as `remote` did earlier:

```
ana@branch:~$ for i in $(seq 15); do curl -s -o /dev/null -d "user=ana" http://www.example.com/login; done
root@sensor:~# jq -r "select(.event_type==\"alert\" and .alert.signature_id==1000201) | .src_ip" /var/log/suricata/eve.json | sort | uniq -c
      5 203.0.113.50
```

**Still only `remote`'s five alerts.** The branch's fifteen posts, which would have produced five more,
produced none, and the rule is untouched for everybody else.

The tools, from narrowest to broadest, and the order to reach for them:

| tool | silences | use it when |
|---|---|---|
| `suppress` with `track` and an address | one rule, for one source or destination | a known, legitimate system triggers a good rule |
| a `threshold` in the threshold file | how often one rule fires | the rule is right and just too frequent |
| editing the rule | what the rule matches | the rule itself is too broad, like lesson 14's `/admin` |
| disabling the rule | everything it would have found | the rule is wrong for this network, and somebody wrote down why |

**Every suppression is a decision to be blind to something**, so it carries a comment saying who made
it, why, and when it should be reviewed. An address suppressed for a monitoring check that was
decommissioned two years ago is a gap anybody using that address can walk through.
