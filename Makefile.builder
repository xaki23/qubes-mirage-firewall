MIRAGE_KERNEL_NAME = qubes_firewall.xen
OCAML_VERSION ?= 4.10.0
SOURCE_BUILD_DEP := firewall-build-dep

firewall-build-dep:
	opam install -y depext
	opam pin add -n -y git+https://github.com/roburio/mirage-platform.git#ocaml-4.09-4.10
	opam depext -i -y mirage.3.7.6 lwt.5.2.0

