(* Copyright (C) 2015, Thomas Leonard <thomas.leonard@unikernel.com>
   See the README file for details. *)

(** The link from us to NetVM (and, through that, to the outside world). *)

open Utils

module Make(Clock : V1.CLOCK) : sig
  type t

  val connect : Dao.network_config -> t Lwt.t
  (** Connect to our NetVM (gateway). *)

  val interface : t -> interface
  (** The network interface to NetVM. *)

  val listen : t -> Router.t -> unit Lwt.t
  (** Handle incoming frames from NetVM. *)
end