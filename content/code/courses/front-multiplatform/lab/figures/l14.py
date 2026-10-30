"""Lesson 14: the signing chain, on Android and for a Linux download."""
from fig import Fig

T = {
 "en": dict(aria="Two signing chains. On Android with Play App Signing: your upload key signs the bundle; Google Play checks that signature, so it knows the upload is yours; Play signs the APKs it builds with the app signing key, which it keeps; and the phone checks that every update carries the same signature as the app it already has. For a Linux download: sha256sum writes a list of the packages' checksums; gpg signs that list with your key; and the person downloading checks the signature with your public key, then the checksums.",
   a="Android, with Play App Signing", b="a Linux download",
   a1=["your upload key", "signs the .aab"], a2=["Google Play checks", "it is yours"], a3=["Play signs the APKs", "with the app key"], a4=["the phone checks", "every update matches"],
   b1=["sha256sum lists", "the packages"], b2=["gpg signs", "the list"], b3=["the person checks", "signature, then sums"],
   keep="you keep this key", plays="Google keeps this one", pub="your public key",
   cap="Each arrow is a check somebody else can make. The key that starts a chain is the one thing you have to keep."),
 "pt": dict(aria="Duas cadeias de assinatura. No Android com o Play App Signing: a sua chave de upload assina o bundle; o Google Play confere essa assinatura, e assim sabe que o envio é seu; o Play assina os APKs que gera com a chave de assinatura do app, que ele guarda; e o celular confere se cada atualização traz a mesma assinatura do app que ele já tem. Para um download no Linux: o sha256sum escreve uma lista com os checksums dos pacotes; o gpg assina essa lista com a sua chave; e quem baixa confere a assinatura com a sua chave pública, depois os checksums.",
   a="Android, com o Play App Signing", b="um download no Linux",
   a1=["a sua chave de upload", "assina o .aab"], a2=["o Google Play confere", "que é seu"], a3=["o Play assina os APKs", "com a chave do app"], a4=["o celular confere", "cada atualização"],
   b1=["o sha256sum lista", "os pacotes"], b2=["o gpg assina", "a lista"], b3=["quem baixa confere", "assinatura e somas"],
   keep="esta chave fica com você", plays="esta fica com o Google", pub="a sua chave pública",
   cap="Cada seta é uma conferência que outra pessoa consegue fazer. A chave que começa uma cadeia é a única coisa que você precisa guardar."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l14-chain", 720, 270, t["aria"])
    f.text(20, 22, t["a"], anchor="start", size=10.5, fill="phosphor", bold=True)
    xs = [20, 200, 380, 560]
    for x, k, s in zip(xs, ["a1", "a2", "a3", "a4"], ["phosphor", "wire", "amber", "wire"]):
        f.box(x, 36, 140, 50, t[k], stroke=s, size=9.5)
    for x in xs[:3]:
        f.arrow([(x + 140, 61), (x + 180, 61)])
    f.text(90, 102, t["keep"], size=9, fill="phosphor", italic=True)
    f.text(450, 102, t["plays"], size=9, fill="amber", italic=True)
    f.text(20, 152, t["b"], anchor="start", size=10.5, fill="amber", bold=True)
    bx = [20, 260, 500]
    for x, k, s in zip(bx, ["b1", "b2", "b3"], ["wire", "phosphor", "wire"]):
        f.box(x, 166, 200, 50, t[k], stroke=s, size=9.5)
    for x in bx[:2]:
        f.arrow([(x + 200, 191), (x + 240, 191)])
    f.text(360, 232, t["keep"], size=9, fill="phosphor", italic=True)
    f.text(600, 232, t["pub"], size=9, fill="paper-dim", italic=True)
    return {"l14-chain": f.json(t["cap"])}
