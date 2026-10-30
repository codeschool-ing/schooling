"""Lesson 1: the two keys of Play App Signing."""
from fig import Fig

T = {
    "en": dict(
        aria="Three stations from left to right. You sign the app bundle with the upload key and upload it. Google Play checks the upload signature against the upload certificate it holds, builds the APKs, and signs them with the app signing key, which it keeps. The phone checks the app signing key, on the first install and on every update. A lost upload key can be reset; a lost app signing key cannot.",
        you="you", play="Google Play", phone="the phone",
        k1="upload key", k2="app signing key", k3="checks the",
        a1="signs the .aab", a2="checks the upload", a2b="signature, then builds", a2c="and signs the APKs",
        a3="checks it on every", a3b="install and update",
        l1="lost: Google resets it", l2="lost: never recovered",
        cap="The upload key only ever meets Google. The key phones see is the one Google holds, which is why it can survive your laptop and why nobody can hand it back.",
    ),
    "pt": dict(
        aria="Três estações da esquerda para a direita. Você assina o app bundle com a chave de upload e o envia. O Google Play confere a assinatura de upload com o certificado de upload que guarda, gera os APKs e os assina com a chave de assinatura do app, que fica com ele. O celular confere a chave de assinatura do app, na primeira instalação e em cada atualização. Uma chave de upload perdida pode ser redefinida; uma chave de assinatura do app perdida, não.",
        you="você", play="Google Play", phone="o celular",
        k1="chave de upload", k2="chave de assinatura do app", k3="confere a",
        a1="assina o .aab", a2="confere a assinatura", a2b="de upload, gera", a2c="e assina os APKs",
        a3="confere em cada", a3b="instalação e atualização",
        l1="perdida: o Google redefine", l2="perdida: nunca se recupera",
        cap="A chave de upload só encontra o Google. A chave que os celulares veem é a que o Google guarda, e é por isso que ela sobrevive ao seu notebook e ninguém consegue devolvê-la.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l01-two-keys", 720, 250, t["aria"])
    xs = [20, 265, 510]
    names = [t["you"], t["play"], t["phone"]]
    for x, n in zip(xs, names):
        f.rect(x, 20, 190, 120, stroke="wire", fill="panel")
        f.text(x + 95, 40, n, bold=True, size=11, fill="phosphor")
    f.box(40, 56, 150, 30, [t["k1"]], stroke="amber", fill="amber", ground="ink")
    f.text(115, 106, t["a1"], size=9.5, fill="paper")
    f.box(285, 56, 150, 30, [t["k2"]], stroke="phosphor", fill="phosphor", ground="ink")
    f.text(360, 100, t["a2"], size=9.5)
    f.text(360, 113, t["a2b"], size=9.5)
    f.text(360, 126, t["a2c"], size=9.5)
    f.text(605, 66, t["k3"], size=9.5, fill="paper-dim")
    f.text(605, 82, t["k2"], size=9.5, fill="phosphor", bold=True)
    f.text(605, 106, t["a3"], size=9.5)
    f.text(605, 119, t["a3b"], size=9.5)
    f.arrow([(210, 80), (263, 80)])
    f.arrow([(455, 80), (508, 80)])
    f.text(237, 68, ".aab", mono=True, size=9, fill="paper-dim")
    f.text(482, 68, ".apk", mono=True, size=9, fill="paper-dim")
    f.rect(20, 160, 680, 70, stroke="wire", fill="ink", dashed=True)
    f.text(115, 195, t["l1"], size=10, fill="amber", italic=True)
    f.text(360, 195, t["l2"], size=10, fill="amber", italic=True)
    same = None if lang == "en" else ["Google Play"]
    return {"l01-two-keys": f.json(t["cap"], same=same)}
