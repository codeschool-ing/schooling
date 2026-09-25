---
title: Ticket: "the website is down"
version: 1
---

The last ticket climbs the whole ladder:

```
ana@laptop:~$ curl -sS https://www.example.com/
curl: (7) Failed to connect to www.example.com port 443 after 1 ms: Couldn't connect to server
ana@www:~$ sudo ss -tlnp | grep -E ":(80|443) " || echo "nothing on 80 or 443"
nothing on 80 or 443
ana@www:~$ sudo nginx
ana@laptop:~$ curl -sS -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
```

`www.example.com` resolved, since curl named the address it tried, and the connection was refused
**after 1 ms**: something on the far end answered at once, and the answer was no. That is step 5. A
refusal comes from the machine itself, with nothing listening on the port (lesson 3); a firewall that
drops would have left curl waiting instead.

On the server, `ss -tlnp` has nothing on 80 or 443, so the web server is not running. Starting it,
here `sudo nginx` and on a normal server `sudo systemctl start nginx`, and asking again gave `200`.
**Refused points at the server, a timeout at the path**, and that one difference decides whose problem a
ticket is. The next question is why the service stopped, and that is in its log, where operating-systems
lesson 17 looked.
