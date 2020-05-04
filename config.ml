(* Copyright (C) 2017, Thomas Leonard <thomas.leonard@unikernel.com>
   See the README file for details. *)

(** Configuration for the "mirage" tool. *)

open Mirage

let table_size =
  let open Functoria_key in
  let info = Arg.info
      ~doc:"The number of NAT entries to allocate."
      ~docv:"ENTRIES" ["nat-table-size"]
  in
  let key = Arg.opt ~stage:`Both Arg.int 5_000 info in
  create "nat_table_size" key

let mirage_nat_pin = "git+https://github.com/roburio/mirage-nat.git#remove-connections"
let mirage_qubes_pin = "git+https://github.com/roburio/mirage-qubes.git#qubesdb-with-commit"

let main =
  foreign
    ~keys:[Functoria_key.abstract table_size]
    ~packages:[
      package "vchan" ~min:"4.0.2";
      package "cstruct";
      package "astring";
      package "tcpip" ~min:"3.7.0";
      package "arp";
      package "arp-mirage";
      package "ethernet";
      package "mirage-protocols";
      package "shared-memory-ring" ~min:"3.0.0";
      package "netchannel" ~min:"1.11.0";
      package "mirage-net-xen";
      package "ipaddr" ~min:"4.0.0";
      package "mirage-qubes" ~pin:mirage_qubes_pin;
      package "mirage-nat" ~pin:mirage_nat_pin;
      package "mirage-logs";
      package "mirage-xen" ~min:"5.0.0";
      package "pf-qubes";
    ]
    "Unikernel.Main" (random @-> mclock @-> job)

let () =
  register "qubes-firewall" [main $ default_random $ default_monotonic_clock]
    ~argv:no_argv
