NAME = "l6-wire"
W, H = 720, 200
LABEL = ("The layout of one Kafka message value written by a schema-registry serialiser: one magic byte, always 0; then four bytes holding the schema id, 00 00 00 01 for id 1; then the Avro body, the values in the schema's order with no field names. The id points to the schema stored in the registry, which the consumer fetches once and keeps.",
         "O layout do valor de uma mensagem Kafka escrita por um serializador com registro de esquemas: um byte mágico, sempre 0; depois quatro bytes com o id do esquema, 00 00 00 01 para o id 1; depois o corpo Avro, os valores na ordem do esquema sem nomes de campos. O id aponta para o esquema guardado no registro, que o consumidor busca uma vez e guarda.")
CAPTION = ("Five bytes in front of every message are enough for any reader to find the schema it was written with.",
           "Cinco bytes na frente de cada mensagem bastam para qualquer leitor achar o esquema com que ela foi escrita.")
PT = {"magic byte": "byte mágico", "schema id": "id do esquema", "Avro body": "corpo Avro",
      "1 byte": "1 byte", "4 bytes, big-endian": "4 bytes, big-endian",
      "the values, in the schema's order, no names": "os valores, na ordem do esquema, sem nomes",
      "the registry": "o registro", "id 1 = sale.avsc, version 1": "id 1 = sale.avsc, versão 1",
      "fetched once, then cached": "buscado uma vez, depois guardado"}
SAME = ["1 byte", "4 bytes, big-endian"]
def draw(s, t):
    y, h = 40, 44
    s.rect(30, y, 70, h, stroke="var(--wire)")
    s.text(65, y + h / 2, "00", size=12, mono=True)
    s.rect(104, y, 170, h, stroke="var(--amber)")
    s.text(189, y + h / 2, "00 00 00 01", size=12, mono=True, fill="var(--amber)")
    s.rect(278, y, 412, h, stroke="var(--phosphor)")
    s.text(484, y + h / 2, "14 6e 61 74 2d 30 30 30 30 30 32 0a …", size=12, mono=True, fill="var(--phosphor)")
    s.text(65, y - 14, t("magic byte"), size=10, weight=600)
    s.text(189, y - 14, t("schema id"), size=10, weight=600, fill="var(--amber)")
    s.text(484, y - 14, t("Avro body"), size=10, weight=600, fill="var(--phosphor)")
    s.text(65, y + h + 16, t("1 byte"), size=9.5, fill="var(--paper-dim)")
    s.text(189, y + h + 16, t("4 bytes, big-endian"), size=9.5, fill="var(--paper-dim)")
    s.text(484, y + h + 16, t("the values, in the schema's order, no names"), size=9.5, fill="var(--paper-dim)")
    s.path("M 189 110 L 189 140", stroke="var(--amber)", arrow=True)
    s.rect(84, 144, 210, 44, stroke="var(--amber)")
    s.text(189, 158, t("the registry"), size=10, weight=600)
    s.text(189, 175, t("id 1 = sale.avsc, version 1"), size=9.5, fill="var(--paper-dim)")
    s.text(310, 166, t("fetched once, then cached"), size=9.5, fill="var(--paper-dim)", anchor="start")
