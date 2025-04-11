package mtl

import "../../types"
import "../common"

MaterialTokenIter :: struct {
    reader:   common.StringIter,
    previous: MaterialToken,
    peek:     Maybe(MaterialToken),
}

material_iter_init :: proc(s: string) -> MaterialTokenIter {
    iter := MaterialTokenIter {
        reader = common.iter_init(s),
        peek   = nil,
    }

    return iter
}

material_iter_current :: proc(iter: ^MaterialTokenIter) -> MaterialToken {
    return iter.previous
}

material_iter_next :: proc(iter: ^MaterialTokenIter) -> (token: MaterialToken, ok: bool) {
    ok = material_iter_advance(iter)
    return iter.previous, ok
}

material_iter_advance :: proc(iter: ^MaterialTokenIter) -> (ok: bool) {
    if material_iter_is_at_end(iter) do return

    switch peeked_value in iter.peek {
    case MaterialToken:
        iter.previous = peeked_value
        iter.peek = nil
    case nil:
        iter.previous = iter_get_next_token(&iter.reader)
    }

    return true
}

material_iter_is_at_end :: proc(iter: ^MaterialTokenIter) -> bool {
    switch peeked_value in iter.peek {
    case MaterialToken:
        return false
    case nil:
        return common.iter_is_at_end(&iter.reader)
    }
    return true
}

material_iter_peek :: proc(iter: ^MaterialTokenIter) -> (token: MaterialToken, ok: bool) {
    if material_iter_is_at_end(iter) do return

    switch peeked_value in iter.peek {
    case MaterialToken:
        token = peeked_value
        ok = true
    case nil:
        token = iter_get_next_token(&iter.reader)
        ok = true
        iter.peek = token
    }

    return
}
