# cython: language_level=3
# distutils: include_dirs = vendor/ls-hpack vendor/ls-hpack/deps/xxhash
# distutils: sources = vendor/ls-hpack/lshpack.c vendor/ls-hpack/deps/xxhash/xxhash.c
# distutils: define_macros = 'XXH_HEADER_NAME="xxhash.h"'
from cpython.mem cimport PyMem_Malloc, PyMem_Free


class HPACKError(Exception):
    pass


class HPACKDecodingError(HPACKError):
    pass


class OversizedHeaderListError(HPACKDecodingError):
    pass


class HeaderTuple(tuple):
    __slots__ = ()
    indexable = True

    def __new__(_cls, *args):
        return tuple.__new__(_cls, args)


class NeverIndexedHeaderTuple(HeaderTuple):
    __slots__ = ()
    indexable = False


cdef class Encoder:
    cdef lshpack_enc* _henc

    def __cinit__(self):
        cdef int rv

        self._henc = <lshpack_enc*> PyMem_Malloc(sizeof(lshpack_enc))
        rv = lshpack_enc_init(self._henc)
        if rv != 0:
            raise Exception('Failed to initialize encoder')

    def __dealloc__(self):
        lshpack_enc_cleanup(self._henc)
        PyMem_Free(self._henc)

    @property
    def header_table_size(self):
        return self._henc.hpe_max_capacity

    @header_table_size.setter
    def header_table_size(self, value):
        lshpack_enc_set_max_capacity(self._henc, value)

    def encode(self, headers):
        cdef unsigned char buf[8192]
        cdef unsigned char *buf_pos = buf
        cdef unsigned char *buf_end = buf + 8192
        cdef int indexed_type

        for t in headers:
            k, v = t
            if isinstance(t, HeaderTuple):
                if t.indexable:
                    indexed_type = 0
                else:
                    indexed_type = 2
            else:
                indexed_type = 0

            buf_pos = lshpack_enc_encode(
                self._henc,
                buf_pos,
                buf_end,
                k.encode('utf-8'),
                len(k),
                v.encode('utf-8'),
                len(v),
                indexed_type,
            )
        return buf[:8192 - (buf_end - buf_pos)]


cdef class Decoder:
    cdef lshpack_dec* _hdec

    def __cinit__(self):
        self._hdec = <lshpack_dec*> PyMem_Malloc(sizeof(lshpack_dec))
        lshpack_dec_init(self._hdec)

    def __dealloc__(self):
        lshpack_dec_cleanup(self._hdec)
        PyMem_Free(self._hdec)

    @property
    def header_table_size(self):
        return self._hdec.hpd_cur_max_capacity

    @header_table_size.setter
    def header_table_size(self, value):
        lshpack_dec_set_max_capacity(self._hdec, value)

    @property
    def max_header_list_size(self):
        return None

    @max_header_list_size.setter
    def max_header_list_size(self, value):
        pass

    def decode(self, data, raw=False):
        cdef const unsigned char *src = data
        cdef const unsigned char *src_end = src + len(data)
        cdef char out[0x100]
        cdef unsigned name_len
        cdef unsigned val_len
        cdef int rv

        headers = []
        while src < src_end:
            rv = lshpack_dec_decode(
                self._hdec,
                &src,
                src + len(data),
                out,
                out + sizeof(out),
                &name_len,
                &val_len,
            )
            if rv == 0:
                name = out[:name_len]
                value = out[name_len:name_len+val_len]
                headers.append(HeaderTuple(
                    name if raw else name.decode('utf-8'),
                    value if raw else value.decode('utf-8'),
                ))
            else:
                raise HPACKDecodingError('Decode error')
        return headers
