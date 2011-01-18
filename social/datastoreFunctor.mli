(*
 * datastore.ml - william@corefarm.com
 * (c) 2010 Hypios
 * fast and efficient functor for quick labelled data retrieval
 *
 * *
 * depends on HyGears_ptree
 * 20/10/2010 1:51
 *)

(**
This module implements, for a given type, whose values are stored in
a database, a memory copy of the database, with fast string search and
linear complex lookup.
*)

module type DATA = sig
  type t
  val load : int64 -> t Lwt.t
  val load_all : unit -> t list Lwt.t
  val save : t -> unit Lwt.t
  val delete : t -> unit Lwt.t
  val to_strings : t -> string list
  val id : t -> int64
(*
  val loaders : (int64 -> t list Lwt.t) array
  val filters : (int64 -> t -> bool) array
*)
end

type 'a custom_accessor = {
  get : int64 -> 'a list Lwt.t;
  insert : int64 -> 'a -> unit Lwt.t;
  remove : int64 -> 'a -> unit Lwt.t;
}

module Make : functor (Data : DATA) ->
sig
  val get : int64 -> Data.t Lwt.t
  val insert : Data.t -> unit Lwt.t
  val remove : Data.t -> unit Lwt.t
  val fold : string -> ('a -> Data.t -> 'a Lwt.t) -> 'a -> 'a Lwt.t
  val fold_indices :
    string -> ('a -> int64 -> 'a Lwt.t) -> 'a -> 'a Lwt.t
  val init : unit -> unit Lwt.t
  val custom_insert : int64 -> Data.t -> unit Lwt.t
  val register_callback : (unit -> unit Lwt.t) -> unit


  (* Instead of creating an array of custom_accessors, with possible
     bugs related to bad choice of index, use the new
     [make_custom_accessor] to create named custom_accessors. *)
  (*  val custom : Data.t custom_accessor array *)

  val make_custom_accessor :
    (int64 -> Data.t -> bool) -> Data.t custom_accessor

end
