package device_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/device"
)

func with(headers map[string]string) *http.Request {
	r := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	for name, value := range headers {
		r.Header.Set(name, value)
	}
	return r
}

func TestTheHintsAnswerTheThreeShapes(t *testing.T) {
	for _, c := range []struct {
		name    string
		headers map[string]string
		want    string
	}{
		{
			name:    "a handset says it is mobile",
			headers: map[string]string{device.HeaderMobile: "?1", device.HeaderPlatform: `"Android"`},
			want:    device.Phone,
		},
		{
			/* AN IPAD IS NOT MOBILE AND IS NOT A COMPUTER, which is the one
			   case a naive reading gets wrong: Chromium sends `?0` for it, so
			   "not mobile" alone would file every tablet under laptops. */
			name:    "a tablet is not mobile and is on a handset platform",
			headers: map[string]string{device.HeaderMobile: "?0", device.HeaderPlatform: `"iOS"`},
			want:    device.Tablet,
		},
		{
			name:    "a laptop is not mobile and is on a desktop platform",
			headers: map[string]string{device.HeaderMobile: "?0", device.HeaderPlatform: `"macOS"`},
			want:    device.Computer,
		},
		{
			/* A PLATFORM THIS LIST HAS NEVER HEARD OF IS A COMPUTER, and that
			   is the direction the list should fail in: the specification's
			   list grows with desktop platforms far more often than with
			   handset ones. */
			name:    "an unheard-of platform is a computer rather than a refusal",
			headers: map[string]string{device.HeaderMobile: "?0", device.HeaderPlatform: `"Fuchsia"`},
			want:    device.Computer,
		},
		{
			/* NOT MOBILE WITH NOTHING TO SPLIT IT BY. Answering `computer`
			   here would be the likelier guess and would put every tablet on a
			   browser that strips the platform hint into the wrong row, with
			   nothing about the number looking wrong. */
			name:    "not mobile with no platform is not a guess",
			headers: map[string]string{device.HeaderMobile: "?0"},
			want:    device.Unknown,
		},
		{
			name:    "a value that is not a structured boolean is not a hint",
			headers: map[string]string{device.HeaderMobile: "true"},
			want:    device.Unknown,
		},
		{
			name:    "nothing at all",
			headers: nil,
			want:    device.Unknown,
		},
	} {
		t.Run(c.name, func(t *testing.T) {
			if got := device.Of(with(c.headers)); got != c.want {
				t.Errorf("device.Of answered %q, want %q", got, c.want)
			}
		})
	}
}

func TestThePageAnswersForBrowsersThatSendNoHint(t *testing.T) {
	/* THE HOLE THIS CLOSES is every iPhone on Safari and every Firefox, which
	   send neither hint — a big enough share that a report without them would
	   be reporting Chromium and calling it the audience. */
	got := device.Of(with(map[string]string{device.HeaderReported: "phone"}))
	if got != device.Phone {
		t.Errorf("a page saying it is a phone answered %q", got)
	}

	if got := device.Of(with(map[string]string{device.HeaderReported: "PHONE"})); got != device.Phone {
		t.Errorf("the page's answer is not read case-insensitively: %q", got)
	}
}

func TestTheHintBeatsThePage(t *testing.T) {
	/* THE ORDER IS THE WHOLE POLICY. Both are the caller's in the end, and one
	   of them is at least not something a page author chose. */
	got := device.Of(with(map[string]string{
		device.HeaderMobile:   "?1",
		device.HeaderPlatform: `"Android"`,
		device.HeaderReported: "computer",
	}))
	if got != device.Phone {
		t.Errorf("the page's answer overrode the browser's hint: %q", got)
	}
}

func TestTheHeaderIsBoundedToTheFourWords(t *testing.T) {
	/* THIS IS A COLUMN A CLIENT CAN WRITE INTO, and the bound is what stops it
	   being a column a client can write ANYTHING into — a report grouping by a
	   dimension somebody chose freely is a report somebody else authors. */
	for _, said := range []string{
		"iPhone 15 Pro", "", "  ", "desktop", "phone; drop table events",
	} {
		if got := device.Of(with(map[string]string{device.HeaderReported: said})); got != device.Unknown {
			t.Errorf("the page said %q and this recorded %q, which is not one of the four",
				said, got)
		}
	}
}

func TestTheContextNeverAnswersEmpty(t *testing.T) {
	/* A HANDLER REACHED WITHOUT THE MIDDLEWARE gets a word rather than an empty
	   string. The columns this lands in refuse an empty one, and the failure
	   would be an INSERT three layers down whose message says nothing about a
	   middleware. */
	if got := device.FromContext(context.Background()); got != device.Unknown {
		t.Errorf("a context nothing wrote to answered %q", got)
	}
}

func TestTheMiddlewarePutsItWhereEmissionReadsIt(t *testing.T) {
	var seen string
	handler := device.Kind()(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		seen = device.FromContext(r.Context())
	}))

	handler.ServeHTTP(httptest.NewRecorder(), with(map[string]string{
		device.HeaderMobile: "?1",
	}))
	if seen != device.Phone {
		t.Errorf("the middleware put %q in the context", seen)
	}
}

func TestKnownIsTheClosedList(t *testing.T) {
	for _, word := range []string{device.Phone, device.Tablet, device.Computer, device.Unknown} {
		if !device.Known(word) {
			t.Errorf("%q is one of the four and `Known` says otherwise", word)
		}
	}
	for _, word := range []string{"", "mobile", "desktop", "watch"} {
		if device.Known(word) {
			t.Errorf("%q is not one of the four and `Known` admits it", word)
		}
	}
}
