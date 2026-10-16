---
title: Rotating a credential that has to be static
version: 1
---

Some credentials cannot be made on demand: the Git server issues tokens, and the image automation of
lesson 7 needs one that works at three in the morning without anybody. Those are rotated, and **a
rotation is four steps in a fixed order**, because each step only removes risk if the one before it
worked:

1. make the new credential, while the old one still works;
2. put the new one everywhere the old one was used;
3. check that everything works with the new one;
4. revoke the old one, and check that it is refused.

Done in another order, it is an outage: revoke first and the automation stops until somebody
notices; deliver without checking and the revocation breaks whatever was missed.

`image-bot`'s token is the example. The new one gets a name of its own, so that the two can be told
apart in Gitea's list:

```
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation-2 --scopes write:repository --raw > ~/image-bot-2.token 2>/dev/null && chmod 600 ~/image-bot-2.token
ana@laptop:~$ curl -s -u image-bot:change-me-please http://localhost:3000/api/v1/users/image-bot/tokens | jq -r '.[].name'
automation-2
automation
```

The Secret Flux reads it from is replaced in place, with the same command that made it in lesson 7:

```
ana@laptop:~$ flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot-2.token)"
► git secret 'fleet-writer-auth' created in 'flux-system' namespace
ana@laptop:~$ flux reconcile source git fleet-writer
► annotating GitRepository fleet-writer in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:2ae2f398ededc41379cfd3116d0bcc90c97c2269
ana@laptop:~$ flux get sources git fleet-writer
NAME        	REVISION          	SUSPENDED	READY	MESSAGE                                           
fleet-writer	main@sha1:2ae2f398	False    	True 	stored artifact for revision 'main@sha1:2ae2f398'	
```

`flux reconcile` is step 3: Flux fetched `fleet` with the Secret it now holds, so the new token
works. Both tokens are valid at this point, which is what makes the order safe.

And only then the old token goes. Gitea lets an account delete its own tokens, by name:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -u image-bot:change-me-please -X DELETE http://localhost:3000/api/v1/users/image-bot/tokens/automation
204
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: token $(cat ~/image-bot.token)" http://localhost:3000/api/v1/repos/ana/fleet
401
ana@laptop:~$ mv ~/image-bot-2.token ~/image-bot.token
ana@laptop:~$ flux reconcile source git fleet-writer && flux get sources git fleet-writer
► annotating GitRepository fleet-writer in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:2ae2f398ededc41379cfd3116d0bcc90c97c2269
NAME        	REVISION          	SUSPENDED	READY	MESSAGE                                           
fleet-writer	main@sha1:2ae2f398	False    	True 	stored artifact for revision 'main@sha1:2ae2f398'	
```

`204` for the deletion, and `401` for the old token a moment later: refused, which is the check of
step 4. The new token moves into the old file's place, and Flux still fetches.

**The order is the same for every static credential in this course.** The cosign key of lesson 8
gets its new public key published beside the old one. The age key of lesson 9 needs every file
re-encrypted to both keys first. The Sealed Secrets controller does it on its own, adding a new key
and keeping the old. What changes from one to the next is only where step 2 has to reach, and that
list is worth writing down before the day it is needed.
