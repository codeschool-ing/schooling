"""Exam questions for lesson 7: screen density, dp, points and assets."""
from exgen import Q, C


def H(n):
    return (f"Lesson {n}.", f"Aula {n}.")


QS = [
Q("@", "", "numeric", "medium",
  ("An Android screen is 240 dpi. How many physical pixels wide is a 32 dp view on it?",
   "Uma tela Android tem 240 dpi. Quantos pixels físicos de largura tem uma view de 32 dp nela?"),
  hint=H(7), value=48, tolerance=0, unit=("px", "px")),
Q("@", "", "matching", "easy",
  ("Match each density bucket to its approximate dots per inch.",
   "Associe cada bucket de densidade aos pontos por polegada aproximados dele."),
  hint=H(7), pairs=[(("mdpi", "mdpi"), ("160", "160")), (("hdpi", "hdpi"), ("240", "240")),
                    (("xhdpi", "xhdpi"), ("320", "320")), (("xxhdpi", "xxhdpi"), ("480", "480"))],
  distractors=[("400", "400")]),
Q("@", "", "quiz", "medium",
  ("A developer writes a margin as 16.sp in Compose. What goes wrong when a user picks the largest text size?",
   "Um desenvolvedor escreve uma margem como 16.sp no Compose. O que dá errado quando o usuário escolhe o maior tamanho de texto?"),
  hint=H(7), choices=[
   C(False, "Nothing; sp and dp are the same unit", "Nada; sp e dp são a mesma unidade",
     "They are equal only at the default text size.", "Eles só são iguais no tamanho de texto padrão."),
   C(True, "The margin grows with the text, though only the text should", "A margem cresce com o texto, embora só o texto devesse",
     "Right: sp is for text sizes, never for layout.", "Isso: sp é para tamanhos de texto, nunca para layout."),
   C(False, "The margin shrinks to zero", "A margem encolhe até zero",
     "Larger text makes sp larger, not smaller.", "Texto maior deixa o sp maior, não menor."),
   C(False, "Compose refuses to compile it", "O Compose se recusa a compilar",
     "It compiles; the mistake shows only at run time.", "Compila; o erro só aparece em execução."),
  ]),
Q("@", "", "quiz", "medium",
  ("Why is an app's plus-sign icon better kept as one vector than as a set of PNGs?",
   "Por que o ícone de mais de um app fica melhor como um vetor do que como um conjunto de PNGs?"),
  hint=H(7), choices=[
   C(False, "Vectors are drawn by the GPU at no cost at all", "Vetores são desenhados pela GPU sem custo nenhum",
     "A vector costs drawing time; for a small icon it is negligible.", "Um vetor custa tempo de desenho; para um ícone pequeno é desprezível."),
   C(False, "PNGs are not allowed in Android apps", "PNGs não são permitidos em apps Android",
     "They are allowed, one per density folder.", "Eles são permitidos, um por pasta de densidade."),
   C(False, "Stores reject apps with raster icons", "As lojas rejeitam apps com ícones raster",
     "No store rule is involved.", "Nenhuma regra de loja está envolvida."),
   C(True, "One file is sharp at every density", "Um arquivo é nítido em toda densidade",
     "Right, where a raster set needs a file per density and still goes soft when one is missing.", "Isso, enquanto um conjunto raster precisa de um arquivo por densidade e ainda fica borrado quando falta um."),
  ]),
Q("@", "", "quiz", "hard",
  ("A React Native screen downloads a thumbnail shown at width: 100. On a phone where PixelRatio.get() returns 3, what pixel width should it ask the server for so the image is sharp without waste?",
   "Uma tela React Native baixa uma miniatura exibida com width: 100. Num celular em que PixelRatio.get() devolve 3, que largura em pixels ela deve pedir ao servidor para a imagem sair nítida sem desperdício?"),
  hint=H(7), choices=[
   C(False, "100 pixels, the layout width", "100 pixels, a largura do layout",
     "100 is in density-independent units; the screen needs three pixels per unit.", "100 está em unidades independentes de densidade; a tela precisa de três pixels por unidade."),
   C(True, "300 pixels", "300 pixels",
     "Right: getPixelSizeForLayoutSize(100) on a ratio of 3.", "Isso: getPixelSizeForLayoutSize(100) numa proporção de 3."),
   C(False, "900 pixels, three squared times the width", "900 pixels, três ao quadrado vezes a largura",
     "The ratio applies to each side once; nine is the factor in area.", "A proporção se aplica a cada lado uma vez; nove é o fator na área."),
   C(False, "The largest the server has, to be safe", "A maior que o servidor tiver, por segurança",
     "That decodes pixels the screen never shows.", "Isso decodifica pixels que a tela nunca mostra."),
  ]),
]
