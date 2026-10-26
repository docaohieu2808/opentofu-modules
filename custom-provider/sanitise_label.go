package main

import "strings"

// maxLabelLength is the GCP limit for label keys and values.
const maxLabelLength = 63

// sanitiseLabel turns arbitrary text into a valid GCP label: lower-case, every character outside
// [a-z0-9-] becomes "-", and the result is cut to 63 characters. "Dev/Staging" -> "dev-staging".
func sanitiseLabel(s string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(s) {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9', r == '-':
			b.WriteRune(r)
		default:
			b.WriteRune('-')
		}
	}
	out := b.String()
	if len(out) > maxLabelLength {
		out = out[:maxLabelLength]
	}
	return out
}
