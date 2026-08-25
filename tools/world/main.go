// Command world turns Natural Earth's country outlines into the path table the
// console's map draws.
//
// # WHY THE OUTPUT IS COMMITTED AND THE INPUT IS NOT
//
// The input is 838 KB of GeoJSON that never changes — borders move, but not on
// the timescale a repository cares about, and not at the scale this draws at.
// Committing it would be most of a megabyte carried forever so that a command
// nobody runs twice can be run again.
//
// The OUTPUT is what the console loads, so it has to be in the repository
// anyway. So the arrangement is the opposite of the country database's: there,
// the file is the thing and the code around it is small; here, the file is a
// derivation and this program is what says how it was derived.
//
//	curl -sfLO https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_admin_0_countries.geojson
//	go run ./tools/world ne_110m_admin_0_countries.geojson > internal/console/ui/app/screens/world.js
//
// # NATURAL EARTH IS PUBLIC DOMAIN
//
// No attribution is required — its own terms say so in those words. That is why
// it is the source rather than one of the many SVG world maps derived from it:
// the derivations carry whatever licence somebody put on them, and a map on a
// staff console is exactly the kind of file nobody ever re-checks the terms of.
//
// # EQUIRECTANGULAR, AND NOT MERCATOR
//
// x is the longitude and y is the negated latitude, which is the simplest
// projection there is and looks a little stretched near the poles.
//
// MERCATOR WOULD BE THE WRONG KIND OF WRONG. It is what a web map uses because
// it preserves angles for navigation, and it inflates area with latitude —
// Greenland drawn the size of Africa. This map's whole subject is HOW MANY
// PEOPLE are in a place, so a projection that silently multiplies the northern
// countries is a projection that argues with the numbers printed beside it.
//
// # ANTARCTICA IS DROPPED, DELIBERATELY
//
// It spans the whole bottom of an equirectangular map and stretches to several
// times its real width, so it takes about a third of the height to say
// something about a continent with no students on it. If somebody ever studies
// from a research station, they are in the list below the map like everybody
// else — the map is the picture and the list is the report.
package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"sort"
	"strings"
)

// How many rings of one country survive.
//
// A COUNTRY IS KEPT WHOLE UNTIL IT IS RIDICULOUS. Indonesia and the Philippines
// are hundreds of islands at this scale and most of them are a pixel; keeping
// every one triples the file for detail nobody can see. The largest few carry
// the shape somebody recognises, and a country is never reduced to nothing —
// the biggest ring is always kept, so an island nation stays on the map.
const mostRings = 12

// Decimal places kept on every coordinate. One tenth of a degree is about
// eleven kilometres, which at the width this is drawn at is well under a pixel.
const places = 1

type collection struct {
	Features []struct {
		Properties map[string]any  `json:"properties"`
		Geometry   json.RawMessage `json:"geometry"`
	} `json:"features"`
}

type geometry struct {
	Type        string          `json:"type"`
	Coordinates json.RawMessage `json:"coordinates"`
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: world <ne_110m_admin_0_countries.geojson>")
		os.Exit(2)
	}

	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	var all collection
	if err := json.Unmarshal(raw, &all); err != nil {
		fmt.Fprintf(os.Stderr, "reading the geojson: %v\n", err)
		os.Exit(1)
	}

	paths := map[string]string{}
	var skipped []string

	for _, f := range all.Features {
		code := codeOf(f.Properties)
		name, _ := f.Properties["NAME"].(string)

		if code == "aq" {
			continue // see the package comment
		}
		if code == "" {
			// A territory Natural Earth carries with no ISO code of its own —
			// Northern Cyprus, Somaliland, Kosovo at some vintages. The events
			// this map colours are keyed by ISO code, so a shape with none can
			// never be coloured; drawing it would be a grey hole somebody
			// reports as a bug.
			skipped = append(skipped, name)
			continue
		}

		d := pathOf(f.Geometry)
		if d == "" {
			skipped = append(skipped, name)
			continue
		}
		paths[code] = d
	}

	if len(paths) == 0 {
		fmt.Fprintln(os.Stderr, "no country came out of that file, which cannot be right")
		os.Exit(1)
	}

	write(paths, skipped)
}

// codeOf answers the ISO alpha-2 code, lower case.
//
// `ISO_A2_EH` FIRST, BECAUSE `ISO_A2` IS `-99` FOR SEVERAL REAL COUNTRIES.
// Natural Earth leaves it unset where a sovereignty is disputed or where the
// mainland and its overseas parts are coded separately — France and Norway are
// both `-99` in the plain field. `_EH` is the same list with those filled in,
// and without it the map would be missing two countries with students in them
// and nobody would know why.
func codeOf(properties map[string]any) string {
	for _, key := range []string{"ISO_A2_EH", "ISO_A2"} {
		code, _ := properties[key].(string)
		code = strings.ToLower(strings.TrimSpace(code))
		if len(code) == 2 && code[0] >= 'a' && code[0] <= 'z' {
			return code
		}
	}
	return ""
}

func pathOf(raw json.RawMessage) string {
	var g geometry
	if err := json.Unmarshal(raw, &g); err != nil {
		return ""
	}

	var rings [][][]float64
	switch g.Type {
	case "Polygon":
		var polygon [][][]float64
		if err := json.Unmarshal(g.Coordinates, &polygon); err != nil {
			return ""
		}
		rings = polygon
	case "MultiPolygon":
		var multi [][][][]float64
		if err := json.Unmarshal(g.Coordinates, &multi); err != nil {
			return ""
		}
		for _, polygon := range multi {
			rings = append(rings, polygon...)
		}
	default:
		return ""
	}

	// The largest few, by the area of the box around them. Area of the ring
	// itself would be more correct and is not worth it: what this decides is
	// which specks to drop, and a speck is small by any measure.
	sort.SliceStable(rings, func(i, j int) bool { return boxOf(rings[i]) > boxOf(rings[j]) })
	if len(rings) > mostRings {
		rings = rings[:mostRings]
	}

	var d strings.Builder
	for _, ring := range rings {
		if len(ring) < 3 {
			continue
		}
		for at, point := range ring {
			if len(point) < 2 {
				continue
			}
			if at == 0 {
				d.WriteString("M")
			} else {
				d.WriteString("L")
			}
			// x is the longitude; y is the NEGATED latitude, because SVG's y
			// grows downwards and the north pole is at the top of every map
			// anybody has ever read.
			fmt.Fprintf(&d, "%s %s", round(point[0]), round(-point[1]))
		}
		d.WriteString("Z")
	}
	return d.String()
}

func boxOf(ring [][]float64) float64 {
	if len(ring) == 0 {
		return 0
	}
	minX, maxX := math.Inf(1), math.Inf(-1)
	minY, maxY := math.Inf(1), math.Inf(-1)
	for _, p := range ring {
		if len(p) < 2 {
			continue
		}
		minX, maxX = math.Min(minX, p[0]), math.Max(maxX, p[0])
		minY, maxY = math.Min(minY, p[1]), math.Max(maxY, p[1])
	}
	return (maxX - minX) * (maxY - minY)
}

// round drops the digits nobody can see and then the zeroes nobody needs.
func round(v float64) string {
	s := fmt.Sprintf("%.*f", places, v)
	s = strings.TrimSuffix(s, ".0")
	if s == "-0" {
		return "0"
	}
	return s
}

func write(paths map[string]string, skipped []string) {
	codes := make([]string, 0, len(paths))
	for code := range paths {
		codes = append(codes, code)
	}
	sort.Strings(codes)

	var bytes int
	for _, d := range paths {
		bytes += len(d)
	}

	fmt.Printf(`/* ==========================================================================
   The world's outlines, keyed by ISO 3166-1 alpha-2.

   GENERATED BY %s. Do not edit it by hand: the next regeneration
   would silently throw the edit away, which is the one thing a generated file
   must never let somebody do quietly. That command is in the tool's own
   comment, along with where the data comes from and why the projection is what
   it is.

   The source is Natural Earth, which is public domain and requires no
   attribution. %d countries, %d KB of path data.
   ========================================================================== */

/* The box the paths are drawn in: the whole of longitude and the latitudes
   that are left once Antarctica is dropped. It is exported because the screen
   needs it for the viewBox attribute, and a second copy of four numbers is a
   second copy that stops matching. */
export const BOX = '-180 -84 360 145';

export const WORLD = {
`, "tools/world", len(codes), bytes/1024)

	for _, code := range codes {
		fmt.Printf("  %s: '%s',\n", code, paths[code])
	}
	fmt.Println("};")

	if len(skipped) > 0 {
		sort.Strings(skipped)
		fmt.Fprintf(os.Stderr, "%d shapes with no ISO alpha-2 code, left out because nothing "+
			"could ever colour them: %s\n", len(skipped), strings.Join(skipped, ", "))
	}
}
