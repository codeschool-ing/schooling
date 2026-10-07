---
title: Being inside is not enough
version: 1
---

The application gets a front door that checks identity, and the machines need identities to show it.
Save this script beside `nslab.sh` and run it once the lab is up:

```schooling-example
{"language": "sh", "file": "identities.sh", "parts": [{"code": "#!/bin/bash\n# identities.sh: lesson 20's certificates, issued from the lab's CA.\nset -euo pipefail\ncd /lab/ca\nmk() {  # mk NAME EXTENSIONS START END SAN\n  openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj \"/CN=$1\" -keyout \"$1.key\" -out \"$1.csr\" 2>/dev/null\n  { sed -n \"/^\\[$2\\]/,/^\\[/p\" ca.cnf | sed '$d'; if [ -n \"$5\" ]; then echo \"subjectAltName = $5\"; fi; } > \"$1.ext\"\n  openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile \"$1.ext\" -extensions \"$2\" -startdate \"$3\" -enddate \"$4\" -in \"$1.csr\" -out \"$1.crt\" -notext 2>/dev/null\n}\nmk app.corp.example.com server 20260928000000Z 20261228000000Z DNS:app.corp.example.com\nmk www-client client 20260928000000Z 20261228000000Z \"\"\nmk www-client-old client 20260601000000Z 20260831000000Z \"\"", "note": "Three certificates from the company's issuing CA, with fixed dates as lesson 12 issued one: `app.corp.example.com` for the application's TLS listener, `www-client` for the proxy to prove who it is, and an old client certificate for the proxy that expired on 31 August 2026. Run it on your own computer, after `nslab.sh up`, with `sudo bash identities.sh`."}, {"code": "mkdir -p /lab/app/root/tls /lab/www/root/tls\ncat app.corp.example.com.crt issuing.crt > /lab/app/root/tls/app.crt; cp app.corp.example.com.key /lab/app/root/tls/app.key\ncat issuing.crt root.crt > /lab/app/root/tls/clients-ca.crt\ncp www-client.crt www-client.key www-client-old.crt www-client-old.key /lab/www/root/tls/\nchmod 600 /lab/app/root/tls/*.key /lab/www/root/tls/*.key", "note": "Each goes to the machine that uses it, with its key, in `/root/tls`. `app` also gets the two CA certificates it will check clients against."}]}
```

On `app`, nginx then listens on 8443 with TLS and **requires a client certificate** signed by the
company's CA, and among valid ones admits only the proxy's. The file below is `/root/nginx-app.conf`
there:

```
root@app:~# cat nginx-app.conf
pid /var/log/lab/nginx.pid;
error_log /var/log/lab/nginx-error.log;
events {}
http {
    log_format who "$remote_addr $ssl_client_s_dn $ssl_client_verify $request_uri $status";
    access_log /var/log/lab/nginx-access.log who;
    server {
        listen 192.168.20.10:8443 ssl;
        server_name app.corp.example.com;
        ssl_certificate     /root/tls/app.crt;
        ssl_certificate_key /root/tls/app.key;
        ssl_protocols TLSv1.3;
        ssl_client_certificate /root/tls/clients-ca.crt;
        ssl_verify_client on;
        ssl_verify_depth 2;
        location / {
            if ($ssl_client_s_dn != "CN=www-client") { return 403; }
            proxy_pass http://192.168.20.10:8080;
        }
    }
}
root@app:~# nginx -c /root/nginx-app.conf -t 2>&1 | tail -1; nginx -c /root/nginx-app.conf
nginx: configuration file /root/nginx-app.conf test is successful
```

Read the `server` block from the security lines down. `ssl_client_certificate` names the CAs whose
client certificates are acceptable, the issuing CA and the root. `ssl_verify_client on` makes a valid
certificate mandatory: no certificate, no connection. And the `if` inside the location is the
authorisation half: a valid certificate is not enough, it has to be **`CN=www-client`**. The access
log records, for every request, the certificate's subject and whether verification succeeded.

The firewall changes to match. The new port is allowed towards the servers from any zone, and the two old
rules to 8080 are removed, so the application can no longer be reached without passing the identity check:

```
root@fw:~# nft insert rule ip filter forward index 2 oifname eth3 ip daddr 192.168.20.10 tcp dport 8443 ct state new accept comment '"the application over TLS: identity decides, not the network"'
root@fw:~# nft -a list chain ip filter forward | grep "dport 8080" | grep -o "comment.*"
comment "staff use the application" # handle 10
comment "the proxy reaches the application" # handle 14
root@fw:~# nft delete rule ip filter forward handle 10; nft delete rule ip filter forward handle 14
root@fw:~# nft list chain ip filter forward | grep -E "dport (8080|8443)" | sed "s/^\t*//"
oifname "eth3" ip daddr 192.168.20.10 tcp dport 8443 ct state new accept comment "the application over TLS: identity decides, not the network"
```

Now `laptop`, still on the staff LAN, still allowed through the firewall to 8443:

```
ana@laptop:~$ curl -sS --resolve app.corp.example.com:8443:192.168.20.10 https://app.corp.example.com:8443/admin/ | grep -o "<title>.*</title>"
<title>400 No required SSL certificate was sent</title>
ana@laptop:~$ probe app:8080
app:8080               blocked
```

**`400 No required SSL certificate was sent`.** The firewall let the connection through, and the
application refused it anyway, because `laptop` could not prove who it was. The old port is blocked.
This is the whole idea at its smallest: the network allowed the packet, and **identity decided**.
