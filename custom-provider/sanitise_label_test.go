package main

import (
	"strings"
	"testing"
)

func TestSanitiseLabel(t *testing.T) {
	cases := []struct{ in, want string }{
		{"Dev/Staging", "dev-staging"},
		{"Platform Ops", "platform-ops"},
		{"ENG-001", "eng-001"},
		{"already-fine-1", "already-fine-1"},
		{"under_score", "under-score"},
		{"caf\u00e9", "caf-"},
		{"", ""},
		{"OpenTofu 1.13.2", "opentofu-1-13-2"},
	}
	for _, c := range cases {
		if got := sanitiseLabel(c.in); got != c.want {
			t.Errorf("sanitiseLabel(%q) = %q, want %q", c.in, got, c.want)
		}
	}
}

func TestSanitiseLabelTruncatesToGCPLimit(t *testing.T) {
	got := sanitiseLabel(strings.Repeat("a", 100))
	if len(got) != maxLabelLength {
		t.Fatalf("length = %d, want %d", len(got), maxLabelLength)
	}
}
