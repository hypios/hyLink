open Lwt 

(* Simple queue implementation *)

type 'a t = { m : Lwt_mutex.t; c : unit Lwt_condition.t; q : 'a Queue.t }

exception Timeout

let create () = { m = Lwt_mutex.create (); c = Lwt_condition.create (); q = Queue.create () }

let add e t =
  Queue.add e t.q;
  Lwt_condition.signal t.c ()

let take t =
  Lwt_mutex.lock t.m >>= fun () ->
    let rec while_empty () =
      if not (Queue.is_empty t.q) then Lwt.return true
      else Lwt_condition.wait t.c ~mutex:t.m >>= while_empty in
    while_empty () >>= fun not_empty ->
      let elts = Queue.fold (fun acc e -> e::acc) [] t.q in
      Queue.clear t.q ;
      Lwt_condition.signal t.c ();
      Lwt_mutex.unlock t.m;
      Lwt.return elts ;;
