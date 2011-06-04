#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = App::Termcast::Server::Web	PACKAGE = App::Termcast::Server::Web::VT102

PROTOTYPES: DISABLE;

SV*
attr_unpack(sv, ...)
    SV *sv
  PREINIT:
    SV *sv_buf;
  PPCODE:

    if (items > 1)
        sv_buf = ST(1);
    else
        sv_buf = sv;

    char *buf = SvPV_nolen(sv_buf);

    EXTEND(SP, 8);

    mPUSHs( newSViv( buf[0] & 7) );
    mPUSHs( newSViv( (buf[0] >> 4) & 7) );
    mPUSHs( newSViv(  buf[1] & 1) );
    mPUSHs( newSViv( (buf[1] >> 1) & 1) );
    mPUSHs( newSViv( (buf[1] >> 2) & 1) );
    mPUSHs( newSViv( (buf[1] >> 3) & 1) );
    mPUSHs( newSViv( (buf[1] >> 4) & 1) );
    mPUSHs( newSViv( (buf[1] >> 5) & 1) );
