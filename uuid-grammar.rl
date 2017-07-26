%%{

    machine UUID;


    action int60_prefix {
        digits = uint(-ABC[fc]-10+4) * 6
        i >>= (60-digits)  // FIXME
    }

    action int60_digit {
        if digits==0 {
            i = 0
            full = true
        } else if digits>=60 {
            length = -p
            fbreak;
        }
        digits+=6
        i <<= 6
        i |= uint64(ABC[fc])
    }

    action value {
        if digits>0 {
            uuid.Value = i << (60-digits)
            digits = 0
        }
        i = uuid.Origin
    }

    action origin {
        if digits>0 {
            uuid.Origin = i << (60-digits)
        }
        bare = false
    }

    action uuid_sep {
        uuid.Sign = fc
        i = uuid.Origin
    }

    action uuid {
        length = pe
        if bare && full {
            uuid.Origin = 0
            uuid.Sign = '$'
        }
    }

    action start_uuid {
        bare, full = true, false
    }


    BASE = ( [0-9a-zA-Z~_] @int60_digit )+;
    PREFIX =  [([\{\}\])]  @int60_prefix;
    SIGN = [\-+$%] @uuid_sep;

    VALUE = ( PREFIX | BASE | PREFIX BASE ) %value ;
    ORIGIN = ( ( SIGN | PREFIX | SIGN PREFIX )  BASE? ) %origin ;

    UUID =  (VALUE? ORIGIN?)
            >start_uuid %uuid
           ;

# main := UUID;

}%%

