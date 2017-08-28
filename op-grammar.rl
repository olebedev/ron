%%{

    machine OP;
    include UUID "./uuid-grammar.rl";

    action redef_uuid {
        red = redefSep2Bits(fc)
        if red==0 {
            *uuid = *prev_uuid
        } else {
            *uuid = context.Spec[red]
        }
    }

    action toel_start {
        i = 0
        digits = 0
        old_n = n
        n = int(specSep2Bits(fc))
        uuid = &op.Spec[n]
        *uuid = context.Spec[n]
        if n <= old_n {
            fbreak;
        }
    }

    action toel_uuid {
        prev_uuid = uuid
    }

    action atom_start {
        if ! op.addAtom(atomSep2Bits(fc), uint(p-atoms_at)) {
            fbreak;
        }
    }
    action atom {
    }

    action atoms {
        op.Body = data[atoms_at:p]
    }

    action int_atom {
    }
    action float_atom {
    }
    action string_atom {
    }
    action atoms_start {
        uuid = &blank
        atoms_at = p
    }
    action opterm {
        op.Flags |= opSep2Bits(fc)
    }
    action query {
        op.Flags |= OP_QUERY_BIT
    }

    action next {
        ret = p
        p-=1
        done = true
        fbreak;
    }
    action over {
        ret = p
        p -= 1
        done = true
        fbreak;
    }

    UNIESC = "\\u" [0-9a-fA-F]{4};
    ESC = "\\" [^\n\r];
    CHAR = [^'\n\r\\];

    REDEF = ([`\\|/]|"") @redef_uuid;
    SPEC_UUID = [*#@:] @toel_start space* REDEF UUID %toel_uuid space*;

    INT_ATOM = [\-+]? [0-9]+ %int_atom ;
    FLOAT_ATOM = [\-+]? [0-9]+ "." digit+ ([eE][\-+]?digit+)? %float_atom ;
    STRING_ATOM = (UNIESC|ESC|CHAR)* %string_atom;

    ATOM = (
            "=" space* INT_ATOM  |
            "^" space* FLOAT_ATOM |
            ['] STRING_ATOM ['] |
            ">" space* UUID
            ) >atom_start %atom space*;
    ATOMS = ATOM+ %atoms >atoms_start;

    OPTERM = [,\.;!] @opterm space*;
    QUERY = [?] @query space*;

    NEXT = [*#@:] @next; 

    OP = space* SPEC_UUID* ( QUERY | OPTERM | ATOMS OPTERM? ) NEXT? %/over;

}%%
