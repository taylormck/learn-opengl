package common

is_valid_identifier_char :: proc(c: u8) -> bool {
    switch c {
    case 'a' ..= 'z', 'A' ..= 'Z', '0' ..= '9', '-', '_', '.':
        return true

    case:
        return false
    }
}

is_valid_numerical_char :: proc(c: u8) -> bool {
    switch c {
    case '0' ..= '9', '.':
        return true
    case:
        return false
    }
}

is_digit :: proc(c: rune) -> bool {
    return c >= '0' && c <= '9'
}

is_float :: proc(s: string) -> bool {
    found_period := false
    for c in s {
        if is_digit(c) do continue
        if c != '.' do return false
        if found_period do return false
        found_period = true
    }

    return found_period
}

is_integer :: proc(s: string) -> bool {
    for c in s {
        if !is_digit(c) do return false
    }

    return true
}
