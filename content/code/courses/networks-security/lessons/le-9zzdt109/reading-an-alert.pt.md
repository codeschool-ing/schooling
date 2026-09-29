---
title: Ler um alerta direito
version: 1
---

O `eve.json` guarda o registro completo de cada evento que o Suricata anota, um objeto JSON por
linha. O alerta da seção anterior, com os campos que importam em destaque:

```
root@sensor:~# jq "select(.event_type==\"alert\") | {timestamp, src_ip, dest_ip, dest_port, alert: {action: .alert.action, signature_id: .alert.signature_id, signature: .alert.signature, category: .alert.category}, http: {hostname: .http.hostname, url: .http.url, status: .http.status}}" /var/log/suricata/eve.json
{
  "timestamp": "2026-09-28T17:59:18.623794-0300",
  "src_ip": "203.0.113.50",
  "dest_ip": "192.0.2.80",
  "dest_port": 80,
  "alert": {
    "action": "allowed",
    "signature_id": 1000101,
    "signature": "admin path requested from outside",
    "category": "Potential Corporate Privacy Violation"
  },
  "http": {
    "hostname": "www.example.com",
    "url": "/admin/",
    "status": 200
  }
}
```

Leia na ordem em que um analista leria:

| campo | aqui | a pergunta que ele responde |
|---|---|---|
| `timestamp` | 17:59:18, no fuso horário do laboratório | quando, para alinhar com outros logs |
| `src_ip`, `dest_ip`, `dest_port` | `203.0.113.50` para `192.0.2.80:80` | quem, para o quê |
| `alert.signature_id`, `signature` | 1000101, *admin path requested from outside* | qual regra, e o que o autor quis dizer com ela |
| `alert.action` | **`allowed`** | se alguma coisa foi feita a respeito |
| `http.url`, `http.status` | `/admin/`, **200** | o que foi pedido, e **se funcionou** |

A última linha transforma um alerta num achado. Um `404` significaria que alguém chutou um caminho que
não existe; um `403`, que um controle o recusou. **Um `200` significa que o console de administração
foi servido para a internet**, e a pergunta deixa de ser sobre quem pediu e passa a ser sobre por que
o proxy permitiu.

`action: allowed` é a palavra honesta para o que um IDS faz a cada regra que casa. É também o campo
que muda na próxima seção.

Dois hábitos tornam os alertas úteis em vez de apenas numerosos. **Escreva a mensagem para quem vai
lê-la às 3 da manhã**: *admin path requested from outside* diz o que aconteceu e por que importa;
*rule 7 match* não diz. E **mande cada alerta para um lugar onde alguém olha**, com os registros de
HTTP, DNS e fluxo ao lado, que é o assunto da aula 23.
