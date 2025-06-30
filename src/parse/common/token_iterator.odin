package common

TokenIter :: struct($Token: typeid) {
	reader:       StringIter,
	previous:     Token,
	peek:         Maybe(Token),
	get_token_fn: #type proc(s: ^StringIter) -> (token: Token),
}

token_iter_init :: proc(
	$Token: typeid,
	s: string,
	get_token_fn: #type proc(s: ^StringIter) -> (token: Token),
) -> TokenIter(Token) {
	iter := TokenIter(Token) {
		reader       = string_iter_init(s),
		peek         = nil,
		get_token_fn = get_token_fn,
	}

	return iter
}

token_iter_current :: proc(iter: ^TokenIter($Token)) -> Token {
	return iter.previous
}

token_iter_next :: proc(iter: ^TokenIter($Token)) -> (token: Token, ok: bool) {
	ok = token_iter_advance(iter)
	return iter.previous, ok
}

token_iter_advance :: proc(iter: ^TokenIter($Token)) -> (ok: bool) {
	if token_iter_is_at_end(iter) do return

	switch peeked_value in iter.peek {
	case Token:
		iter.previous = peeked_value
		iter.peek = nil
	case nil:
		iter.previous = iter.get_token_fn(&iter.reader)
	}

	return true
}

token_iter_is_at_end :: proc(iter: ^TokenIter($Token)) -> bool {
	switch peeked_value in iter.peek {
	case Token:
		return false
	case nil:
		return string_iter_is_at_end(&iter.reader)
	}
	return true
}

token_iter_peek :: proc(iter: ^TokenIter($Token)) -> (token: Token, ok: bool) {
	if token_iter_is_at_end(iter) do return

	switch peeked_value in iter.peek {
	case Token:
		token = peeked_value
		ok = true
	case nil:
		token = iter.get_token_fn(&iter.reader)
		ok = true
		iter.peek = token
	}

	return
}
