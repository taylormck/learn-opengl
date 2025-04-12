package common

import "core:log"
import "core:strings"


StringIter :: struct {
    line, column: int,
    reader:       strings.Reader,
}

string_iter_init :: proc(s: string) -> StringIter {
    iter: StringIter
    strings.reader_init(&iter.reader, s)

    return iter
}

string_iter_current :: proc(iter: ^StringIter) -> rune {
    return rune(iter.reader.prev_rune)
}

string_iter_next :: proc(iter: ^StringIter) -> rune {
    next_rune, size, ok := strings.reader_read_rune(&iter.reader)
    // TODO: handle the situation when !ok
    return next_rune
}

string_iter_advance :: proc(iter: ^StringIter) {
    strings.reader_read_rune(&iter.reader)
}

string_iter_is_at_end :: proc(iter: ^StringIter) -> bool {
    return strings.reader_length(&iter.reader) == 0
}

string_iter_slice :: proc(iter: ^StringIter, start, end: i64) -> string {
    return iter.reader.s[start:end]
}
