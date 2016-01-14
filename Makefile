
OCAMLC=ocamlc
OCAMLLIB=$(shell opam config var lib)

NETINCLUDE=netstring netsys
NETLIBS=netsys_oothr.cma netsys.cma netstring.cma

OBJS=chromeotl otlhtml

all: $(OBJS)

chromeotl: chromeotl.ml
	$(OCAMLC) -o $@ $(NETINCLUDE:%=-I $(OCAMLLIB)/%) \
	    unix.cma bigarray.cma str.cma $(NETLIBS) $<

otlhtml: otlhtml.ml
	$(OCAMLC) -o $@ $(NETINCLUDE:%=-I $(OCAMLLIB)/%) \
	    unix.cma bigarray.cma str.cma $(NETLIBS) $<

opam:
	-opam install ocamlnet

clean:
	-@rm -rf *.cmi *.cmo *.cmx

distclean: clean
	-@rm $(OBJS)

