open Lwt.Infix

module Transport (R : Mirage_random.S) (C : Mirage_clock.MCLOCK) = struct
  type +'a io = 'a Lwt.t
  type io_addr = Ipaddr.V4.t * int
  type ns_addr = [ `TCP | `UDP ] * io_addr
  type stack = Router.t * (src_port:int -> dst:Ipaddr.V4.t -> dst_port:int -> Cstruct.t -> (unit, [ `Msg of string ]) result Lwt.t) * (Udp_packet.t * Cstruct.t) Lwt_mvar.t

  type t = {
    nameserver : ns_addr ;
    stack : stack ;
    timeout_ns : int64 ;
  }
  type context = { t : t ; timeout_ns : int64 ref; mutable src_port : int }

  let nameserver t = t.nameserver
  let rng = R.generate ?g:None
  let clock = C.elapsed_ns

  let create ?(nameserver = `UDP, (Ipaddr.V4.of_string_exn "91.239.100.100", 53)) ~timeout stack =
    { nameserver ; stack ; timeout_ns = timeout }

  let with_timeout ctx f =
    let timeout = OS.Time.sleep_ns !(ctx.timeout_ns) >|= fun () -> Error (`Msg "DNS request timeout") in
    let start = clock () in
    Lwt.pick [ f ; timeout ] >|= fun result ->
    let stop = clock () in
    ctx.timeout_ns := Int64.sub !(ctx.timeout_ns) (Int64.sub stop start);
    result

  let connect ?nameserver:_ (t : t) = Lwt.return (Ok { t ; timeout_ns = ref t.timeout_ns ; src_port = 0 })

  let send (ctx : context) buf : (unit, [> `Msg of string ]) result Lwt.t =
    let dst, dst_port = snd ctx.t.nameserver in
    let router, send_udp, _ = ctx.t.stack in
    let src_port = Ports.pick_free_port ~add_list:router.Router.dns_ports ~consult_list:router.Router.nat_ports in
    ctx.src_port <- src_port;
    with_timeout ctx (send_udp ~src_port ~dst ~dst_port buf >|= Rresult.R.open_error_msg)

  let recv ctx =
    let router, _, answers = ctx.t.stack in
    with_timeout ctx
      (Lwt_mvar.take answers >|= fun (_, dns_response) -> Ok dns_response) >|= fun result ->
    router.Router.dns_ports := Ports.remove ctx.src_port !(router.Router.dns_ports);
    result

  let close _ = Lwt.return_unit

  let bind = Lwt.bind

  let lift = Lwt.return
end

