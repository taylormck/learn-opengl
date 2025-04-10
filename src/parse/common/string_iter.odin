package common

StringIter :: struct {
    index, line, column: int,
    data:                string,
}

iter_current :: proc(iter: ^StringIter) -> u8 {
    return iter.data[iter.index]
}

iter_advance :: proc(iter: ^StringIter) {
    iter.index += 1
}
