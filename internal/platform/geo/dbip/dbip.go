// Package dbip answers which country an address is in, out of a database
// embedded in the binary.
//
// # WHY THE FILE IS IN THE REPOSITORY
//
// K-05 says the country is resolved in-process, and the reason it can be is
// this file: DB-IP's Lite database is published under CC BY 4.0, which allows
// redistribution with attribution. MaxMind's GeoLite2 does not — it would mean
// a licence key in CI, a download step in the build, and a binary that cannot
// be built from a checkout on an aeroplane.
//
// A HOSTED LOOKUP IS NOT AN OPTION AND NOT BECAUSE OF THE PRICE. The privacy
// policy says the address is discarded and never leaves us; sending it to
// somebody's API is a transfer, and it would make the published document
// false. The cheapest option and the compliant one happen to be the same one.
//
// # AND IT IS UPDATED QUARTERLY, WHICH IS A DECISION AND NOT A HABIT
//
// The file is about 8 MB and is internally compressed, so git cannot delta one
// version against the next: every update is a whole new object, and history
// never shrinks. Monthly updates would add roughly 45 MB a year to a
// repository that is 36 MB in total; quarterly adds about 15.
//
// What is bought with the other 30 MB is at most three months of staleness in
// a value used to group a report. Blocks of addresses do move between
// countries, but rarely, and a report that says Brazil where the truth became
// Chile last month is not a report anybody acts on differently.
//
// THE AGE IS CHECKED RATHER THAN TRUSTED. A database from three years ago
// answers every query confidently and wrongly, which is the failure this
// repository keeps finding: a number nobody can tell from the truth. The build
// date is inside the file — the one place that cannot be renamed into a lie —
// and a test fails when it is too old.
//
// # ATTRIBUTION
//
// CC BY 4.0 requires the source be credited. See `LICENCE.md` beside the
// database.
package dbip

import (
	_ "embed"
	"fmt"
	"net/netip"
	"strings"
	"time"

	"github.com/oschwald/maxminddb-golang/v2"
)

/* THE NAME CARRIES NO DATE, so an update is a replacement rather than one file
   deleted and another created — the `go:embed` pattern never changes, and the
   diff is one line saying the bytes differ. When the database was built is
   inside it, which is the only copy that cannot drift from the thing it
   describes. */
//go:embed dbip-country-lite.mmdb
var database []byte

// Database is the embedded country database, opened once.
type Database struct {
	reader *maxminddb.Reader
	built  time.Time
}

// Open reads the embedded database.
//
// IT IS CALLED ONCE, AT START-UP, AND THE ERROR IS FATAL THERE RATHER THAN
// HERE. A binary whose own embedded file does not parse is broken in a way no
// request can work around, and a deployment that started anyway would resolve
// every country to `unknown` while looking perfectly healthy.
func Open() (*Database, error) {
	reader, err := maxminddb.OpenBytes(database)
	if err != nil {
		return nil, fmt.Errorf("dbip: reading the embedded country database: %w", err)
	}
	return &Database{reader: reader, built: reader.Metadata.BuildTime()}, nil
}

// Built is when the database was made, read from inside it.
func (d *Database) Built() time.Time { return d.built }

// Close releases it.
func (d *Database) Close() error { return d.reader.Close() }

// country is the only field of a record this reads.
//
// THE LITE DATABASE CARRIES NAMES TOO, in several languages, and none of them
// is wanted: a name is a label for a screen and this is a key for a GROUP BY.
// Reading one would put the display language of whoever wrote the code into
// the data, and "Brasil" and "Brazil" would be two countries.
type country struct {
	Country struct {
		ISOCode string `maxminddb:"iso_code"`
	} `maxminddb:"country"`
}

// Country answers the two-letter code for an address, lowercased, or an empty
// string.
//
// EMPTY IS AN ANSWER AND NOT A FAILURE. An address in no assigned block — and
// there are plenty — is one this database genuinely does not know, which is
// different from one it got wrong. `platform/geo` turns it into `unknown`,
// which is the word the columns already hold.
func (d *Database) Country(addr netip.Addr) string {
	if !addr.IsValid() {
		return ""
	}
	result := d.reader.Lookup(addr)
	if !result.Found() {
		return ""
	}
	var record country
	if err := result.Decode(&record); err != nil {
		// A row this reader cannot decode is a broken database, not a broken
		// request. It is not worth a log line per request: the age check and
		// the tests are where a broken file is caught, and a country nobody
		// could read is the same `unknown` as one nobody had.
		return ""
	}
	return strings.ToLower(strings.TrimSpace(record.Country.ISOCode))
}
