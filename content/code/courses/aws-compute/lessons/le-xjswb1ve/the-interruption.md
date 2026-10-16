---
title: Two minutes' notice, and what to do with them
version: 1
---

The worry about spot is that an instance vanishes without warning. It does not, quite. **When AWS
needs the capacity back, it gives the instance two minutes' notice**, and before that it may give an
earlier, softer signal. What an instance does with those minutes decides whether an interruption
is an event nobody notices or a job that has to start again from the beginning.

None of this section's AWS behaviour could be run: moto never interrupts anything. What follows is
AWS's documentation, and the one script here was run only on the path where nothing happens.

## The two signals

**The interruption notice** is the firm one. Two minutes before AWS stops, hibernates or terminates
the instance, two things appear at once:

- the instance metadata path `/latest/meta-data/spot/instance-action` starts answering, with a small
  JSON document naming the action and the time it will happen. Until then the path answers 404;
- EventBridge receives an event of the type `EC2 Spot Instance Interruption Warning`, carrying the
  instance id and the action.

**The rebalance recommendation** is the early one. When AWS sees that an instance is at elevated
risk of interruption, it may say so sooner: the metadata path
`/latest/meta-data/events/recommendations/rebalance` starts answering, and EventBridge receives an
`EC2 Instance Rebalance Recommendation`. It is a hint, not a promise. It can arrive well before the
notice, at the same moment, or not at all, and an instance that receives one may run for days.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline of one spot instance. It launches. At some point a rebalance recommendation may arrive, on the metadata path events/recommendations/rebalance; it is optional and can come long before the end or not at all. Later the interruption notice arrives on spot/instance-action, two minutes before the instance is stopped or terminated. The two minutes are the drain window.\"><defs><marker id=\"tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 150 L700 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tl-ah)\"></path><path d=\"M80 140 L80 160\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M300 140 L300 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 140 L520 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M660 140 L660 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"80\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">launched</text><text x=\"300\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">rebalance recommendation</text><text x=\"300\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">may come early, late or never</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">interruption notice</text><text x=\"520\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">always two minutes ahead</text><text x=\"660\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">taken back</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">two minutes</text><text x=\"605\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stop new work, hand back the rest</text><rect x=\"300\" y=\"170\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"400\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">time to replace it calmly</text><text x=\"400\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what capacity rebalancing uses</text><text x=\"300\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">events/recommendations/rebalance</text><text x=\"605\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">spot/instance-action</text><text x=\"700\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">times not to scale</text></svg>", "caption": "The two signals of a spot interruption, as AWS documents them. The notice is guaranteed and short; the recommendation is earlier and not guaranteed, which is why a group uses it to launch a replacement but nothing waits for it."}
```

## Listening on the instance

The metadata path is read from the instance itself, so the simplest listener is a small program
beside the application that asks every few seconds. Here is one, in plain shell. **Copy it with the
button on the block and save it as `~/aws/spot-watch.sh`.**

```schooling-example
{"language": "sh", "file": "spot-watch.sh", "parts": [{"code": "#!/bin/sh\n# spot-watch.sh: poll for a spot interruption notice, and drain when one comes\nMD=${MD:-http://169.254.169.254}\nPIDFILE=${PIDFILE:-/run/worker.pid}\n\n", "note": "The metadata service's address, which lesson 7 explains, and the file where the worker writes its process id. Both can be overridden from the environment, which is how the same script is pointed at moto below."}, {"code": "while :; do\n  TOKEN=$(curl -s -X PUT \"$MD/latest/api/token\" \\\n    -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')\n", "note": "An IMDSv2 session token, asked for with a PUT. Lesson 4's template required it, so a GET without one would be refused; lesson 7 says why."}, {"code": "  CODE=$(curl -s -o /tmp/notice -w '%{http_code}' \\\n    -H \"X-aws-ec2-metadata-token: $TOKEN\" \\\n    \"$MD/latest/meta-data/spot/instance-action\")\n", "note": "The one path that matters. On AWS it answers 404 until an interruption is scheduled, and 200 with a small JSON document, the action and its time, from the moment it is. The body goes to a file and only the status code comes back."}, {"code": "  if [ \"$CODE\" = 200 ]; then\n    echo \"notice: $(cat /tmp/notice)\"\n    kill -TERM \"$(cat \"$PIDFILE\")\"\n    exit 0\n  fi\n", "note": "A notice, so drain: send the worker SIGTERM, which a well-written worker takes as an order to finish the job in hand and take no more. Two minutes is the whole budget, so this is not the place to start anything."}, {"code": "  echo \"no notice ($CODE)\"\n  [ -n \"$ONCE\" ] && exit 0\n  sleep 5\ndone\n", "note": "Anything else means no notice yet: look again in five seconds, which leaves almost all of the two minutes for draining. ONCE makes it look a single time, for trying it by hand."}]}
```

On an instance it runs as a service next to the worker. In the lab there is no instance and no
metadata service on `169.254.169.254`, but moto answers the metadata paths on its own port, so the
script can be pointed there and asked to look once:

```
ana@laptop:~/aws$ MD=http://localhost:4567 ONCE=1 sh spot-watch.sh
no notice (500)
```

The script took its "no notice" branch, which is the right answer and for a slightly wrong reason.
**AWS answers 404 when there is no notice; moto answers 500**, because it does not implement the
spot path at all. The script treats anything other than 200 as "not yet", so both lead to the same
branch, and that is a property worth keeping: a listener that crashed on an unexpected answer would
stop listening at the moment it mattered. The branch that drains did not run here or anywhere else
in this course.

## Listening from outside

The same two signals arrive in EventBridge, which is the place to act on them for a whole fleet
rather than one instance at a time: a rule matching both, with a queue or a function as its target.
Lessons 15 and 21 build those targets. The rule itself moto accepts:

```
ana@laptop:~/aws$ aws events put-rule --name spot-warning --event-pattern '{"source": ["aws.ec2"], "detail-type": ["EC2 Spot Instance Interruption Warning", "EC2 Instance Rebalance Recommendation"]}'
{
    "RuleArn": "arn:aws:events:sa-east-1:123456789012:rule/spot-warning"
}
```

On AWS a target on that rule would receive one event per notice, with the instance id in it; it can
deregister the instance from its load balancer, mark its jobs for retry, or write the interruption
down so that somebody can count them. moto stores the rule, and no event will ever match it here.

## What draining means

Two minutes is enough to stop and too short to finish anything long. Draining is therefore a list
of things to stop doing, not a list of things to complete:

1. stop taking new work: leave the load balancer's target group, stop reading from the queue;
2. let the work in hand finish if it can within the time, or checkpoint it if it cannot;
3. hand back what it cannot finish, so that something else picks it up. A queue does this by
   itself: a message that is not deleted becomes visible again after its visibility timeout, which
   lesson 21 explains.

**An application that is safe to stop at any moment needs none of this**, and that is the strongest
argument for writing it that way. For one in an auto scaling group there is also help from the
group itself, which the next section sets up.
