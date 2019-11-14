import hpack.hpack

import lshpack


def test_encode():
    encoder = lshpack.Encoder()
    decoder = hpack.hpack.Decoder()
    headers = [
        (':method', 'post'),
        (':path', '/test'),
        ('content-type', 'application/x-foobar'),
    ]
    assert decoder.decode(encoder.encode(headers)) == headers


def test_decode():
    encoder = hpack.hpack.Encoder()
    decoder = lshpack.Decoder()
    headers = [
        (':method', 'post'),
        (':path', '/test'),
        ('content-type', 'application/x-foobar'),
    ]
    assert decoder.decode(encoder.encode(headers)) == headers
