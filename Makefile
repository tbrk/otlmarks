
OCAMLFIND=ocamlfind

PACKAGES=netstring netsys
NETLIBS=netsys_oothr.cma netsys.cma netstring.cma

OBJS=chromeotl otlhtml

all: $(OBJS)

chromeotl: chromeotl.ml
	$(OCAMLFIND) ocamlc -o $@ $(PACKAGES:%=-package %) \
	    unix.cma bigarray.cma str.cma $(NETLIBS) $<

otlhtml: otlhtml.ml
	$(OCAMLFIND) ocamlc -o $@ $(PACKAGES:%=-package %) \
	    unix.cma bigarray.cma str.cma $(NETLIBS) $<

opam:
	-opam install ocamlfind ocamlnet

clean:
	-@rm -rf *.cmi *.cmo *.cmx

distclean: clean
	-@rm $(OBJS)

