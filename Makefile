
OCAMLFIND=ocamlfind
CPP=gcc -E -P -x c -w

PACKAGES=netstring netsys
NETLIBS=netsys_oothr.cmxa netsys.cmxa netstring.cmxa

OBJS=chromeotl otlhtml

all: $(OBJS)

chromeotl: chromeotl.ml
	$(OCAMLFIND) ocamlopt -o $@ $(PACKAGES:%=-package %) \
	    unix.cmxa bigarray.cmxa str.cmxa $(NETLIBS) $<

otlhtml: otlhtml.ml
	$(OCAMLFIND) ocamlopt -o $@ $(PACKAGES:%=-package %) \
	    -pp '$(CPP)' \
	    unix.cmxa bigarray.cmxa str.cmxa $(NETLIBS) $<

opam:
	-opam install ocamlfind ocamlnet

clean:
	-@rm -rf *.cmi *.cmo *.cmx

distclean: clean
	-@rm $(OBJS)

