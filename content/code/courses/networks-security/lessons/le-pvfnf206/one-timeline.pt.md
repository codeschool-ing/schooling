---
title: Uma linha do tempo
version: 1
---

O sensor também viu `remote`. O `eve.json` dele foi copiado para a coleção, o que no laboratório é
um comando no seu próprio computador, já que o sensor não tem endereço de onde enviar nada:
`sudo mkdir -p /lab/admin/var/log/lab/remote/sensor; sudo cp /lab/sensor/var/log/suricata/eve.json /lab/admin/var/log/lab/remote/sensor/`.
As três fontes agora descrevem o mesmo estranho por três lados: as recusas do firewall, os fluxos do firewall e o alerta do
sensor. Lida separadamente, cada uma é uma lista. **Postas em uma única ordem pelo tempo, elas contam o
que aconteceu.**

Esse é o núcleo do que um **SIEM** faz, e a versão do laboratório é pequena o bastante para ser lida
inteira:

```schooling-example
{"language": "python", "file": "correlate.py", "parts": [{"code": "import json, sys\nfrom datetime import datetime\n\nLOGS = \"/var/log/lab/remote\"\nwho = sys.argv[1]\nevents = []", "note": "O único argumento é o endereço a seguir, e todo registro que o menciona vai para uma única lista."}, {"code": "def lines(path):\n    with open(path) as f:\n        return [json.loads(l) for l in f if l.strip()]", "note": "Todo arquivo da coleção tem um objeto JSON por linha, então um único leitor serve aos três."}, {"code": "for r in lines(f\"{LOGS}/fw/flows.json\"):\n    if who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromtimestamp(r[\"flow.start.sec\"]).astimezone()\n        size = r[\"orig.raw.pktlen\"] + r[\"reply.raw.pktlen\"]\n        events.append((t, \"flow \", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"orig.l4.dport\"]}  {size} bytes'))", "note": "Os fluxos carregam seu início em segundos desde 1970. O tamanho é a soma dos dois sentidos."}, {"code": "for r in lines(f\"{LOGS}/fw/drops.json\"):\n    if who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromisoformat(r[\"timestamp\"])\n        events.append((t, \"drop \", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"dest_port\"]}  {r[\"oob.prefix\"]}'))", "note": "Os descartes carregam um timestamp escrito, e o prefixo diz qual regra recusou o pacote."}, {"code": "for r in lines(f\"{LOGS}/sensor/eve.json\"):\n    if r.get(\"event_type\") == \"alert\" and who in (r[\"src_ip\"], r[\"dest_ip\"]):\n        t = datetime.fromisoformat(r[\"timestamp\"])\n        events.append((t, \"alert\", f'{r[\"src_ip\"]} -> {r[\"dest_ip\"]}:{r[\"dest_port\"]}  {r[\"alert\"][\"signature\"]}'))", "note": "Do sensor, só os alertas. Os registros de HTTP, de fluxo e de estatísticas estão no mesmo arquivo e são ignorados."}, {"code": "for t, kind, what in sorted(events):\n    print(t.strftime(\"%H:%M:%S\"), kind, what)", "note": "Ordenar pelo tempo é a junção inteira. Só tem sentido porque o relógio de todas as fontes concorda."}]}
```

```
root@admin:~# python3 correlate.py 203.0.113.50
18:52:31 flow  203.0.113.50 -> 192.0.2.80:80  835 bytes
18:52:32 flow  203.0.113.50 -> 192.0.2.80:80  1136 bytes
18:52:32 alert 203.0.113.50 -> 192.0.2.80:80  secrets file requested from outside
18:52:32 drop  203.0.113.50 -> 192.0.2.80:22  forward-drop
18:52:33 drop  203.0.113.50 -> 192.0.2.53:22  forward-drop
18:52:34 drop  203.0.113.50 -> 192.168.20.30:5432  forward-drop
18:55:35 drop  203.0.113.50 -> 192.0.2.80:23  forward-drop
18:55:39 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
18:55:40 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
18:55:41 drop  203.0.113.50 -> 192.0.2.80:80  intel-drop
```

Leia de cima para baixo. Às 18:52:31 `remote` carregou a página inicial. Um segundo depois pediu
`/.env`, um arquivo que costuma guardar senhas e chaves, e o sensor levantou seu alerta nessa
requisição. Nos dois segundos seguintes tentou SSH na loja, depois SSH no servidor de nomes, depois o
banco de dados, que nem está na DMZ. Os fluxos dizem que as duas requisições web foram respondidas, 835
e 1.136 bytes no total; os descartes dizem que todas as outras portas continuaram fechadas. Às 18:55:35
voltou para a porta 23. Depois que o feed foi carregado, a regra de inteligência recusou a requisição
seguinte à loja, três pacotes com um segundo de intervalo.

Essa é a resposta que um alerta sozinho não podia dar: **algo mais teve sucesso?** Aqui, não. O único
alerta foi um 404, e as únicas conversas que se completaram foram dois carregamentos de página. O
trabalho que resta é confirmar que `/.env` não existe no servidor, o que o 404 já sugere, e decidir se
o endereço vai para a lista de bloqueio, o que o feed já decidiu.

Um SIEM real acrescenta o que este script deixa de fora: interpretar dezenas de formatos, manter
índices para que um mês seja pesquisado em segundos, regras que geram um incidente a partir de muitos
registros, e os eventos de host da aula 16 ao lado dos da rede. A junção é a mesma, por endereço e por
tempo, e só funciona se os relógios concordam. Toda máquina do laboratório pega a hora do mesmo host;
em uma rede real, **NTP em todo dispositivo é uma pré-condição da correlação**, não um luxo.
