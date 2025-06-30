package common

import "core:strings"

StringIter :: struct {
	// TODO: use these properties to provide nicer error messages
	// line, column: int,
	reader:         strings.Reader,
	previous_value: rune,
	peeked_value:   Maybe(rune),
}

string_iter_init :: proc(s: string) -> StringIter {
	iter: StringIter
	strings.reader_init(&iter.reader, s)

	return iter
}

string_iter_current :: proc(iter: ^StringIter) -> rune {
	return iter.previous_value
}

string_iter_peek :: proc(iter: ^StringIter) -> (next_rune: rune) {
	switch val in iter.peeked_value {
	case rune:
		next_rune = val
	case nil:
		next, _, _ := strings.reader_read_rune(&iter.reader)
		next_rune = next
		iter.peeked_value = next_rune
	}

	return
}

string_iter_next :: proc(iter: ^StringIter) -> rune {
	string_iter_advance(iter)
	return iter.previous_value
}

string_iter_advance :: proc(iter: ^StringIter) {
	switch val in iter.peeked_value {
	case rune:
		iter.previous_value = val
		iter.peeked_value = nil
	case nil:
		// TODO: handle the situation when !ok
		next_rune, _, _ := strings.reader_read_rune(&iter.reader)
		iter.previous_value = next_rune
	}
}

string_iter_is_at_end :: proc(iter: ^StringIter) -> bool {
	switch val in iter.peeked_value {
	case rune:
		return false
	case nil:
		return strings.reader_length(&iter.reader) == 0
	}

	return true
}

string_iter_slice :: proc(iter: ^StringIter, start, end: i64) -> string {
	return iter.reader.s[start:end]
}

string_iter_get_current_index :: proc(iter: ^StringIter) -> i64 {
	switch val in iter.peeked_value {
	case rune:
		return iter.reader.i - 1
	case:
		return iter.reader.i
	}
}
