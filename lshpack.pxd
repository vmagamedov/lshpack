cdef extern from 'vendor/ls-hpack/lshpack.h':
    cdef struct lshpack_enc:
        unsigned hpe_max_capacity

    cdef struct lshpack_dec:
        unsigned hpd_cur_max_capacity

    int lshpack_enc_init (lshpack_enc *)
    void lshpack_enc_cleanup (lshpack_enc *)
    unsigned char * lshpack_enc_encode (
        lshpack_enc *henc,
        unsigned char *dst,
        unsigned char *dst_end,
        const char *name,
        unsigned name_len,
        const char *value,
        unsigned value_len,
        int indexed_type,
    )
    void lshpack_enc_set_max_capacity (lshpack_enc *, unsigned)

    void lshpack_dec_init (lshpack_dec *)
    void lshpack_dec_cleanup (lshpack_dec *)
    int lshpack_dec_decode (
        lshpack_dec *dec,
        const unsigned char **src,
        const unsigned char *src_end,
        char *dst,
        char *dst_end,
        unsigned *name_len,
        unsigned *val_len,
    )
    void lshpack_dec_set_max_capacity (lshpack_dec *, unsigned)
