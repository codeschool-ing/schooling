---
title: A sensor that sees and does not touch
version: 1
---

The company does not want the shop's admin pages requested from the internet. Lesson 3 showed how to
refuse that at the proxy; this lesson asks a different question: **would anybody notice it being
tried?** In your lab this lesson starts from `sudo bash nslab.sh reset`, with the company's policy
loaded on `fw` by `nft -f baseline.nft`. One rule on `sensor`, written into its empty rule file:

```
root@sensor:~# cat /etc/suricata/rules/local.rules
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:1;)
```

It reads like lesson 2's rules: `alert` on HTTP from outside to the company's networks, on the client's
side of an established connection, when the requested path **starts with** `/admin`. `classtype` files
it under a category, which decides the alert's priority. Suricata starts listening on the DMZ:

```
root@sensor:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

Then a request from the internet:

```
ana@remote:~$ curl -s http://www.example.com/admin/
admin console
```

**The request succeeded.** The admin console answered `remote`, because an IDS does not stand in the
way of anything; the proxy of this lab was left without lesson 3's restrictions. What the IDS did
was write it down:

```
root@sensor:~# cat /var/log/suricata/fast.log
09/28/2026-17:59:18.623794  [**] [1:1000101:1] admin path requested from outside [**] [Classification: Potential Corporate Privacy Violation] [Priority: 1] {TCP} 203.0.113.50:39498 -> 192.0.2.80:80
```

One line per alert in `fast.log`: when, which rule and revision (`1:1000101:1`), the message, the
classification and priority, and the connection it saw. That is the view somebody watching a console
gets. The next section reads the full record behind it.
