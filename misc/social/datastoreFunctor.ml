(*
 * datastore.ml - william@corefarm.com
 * (c) 2010 Hypios
 * fast and efficient functor for quick labelled data retrieval
 *
 * *
 * depends on HyGears_ptree
 * 20/10/2010 1:51
 *)

open Lwt

open Misc

(** DATA type signature *)
module type DATA =
  sig
    type t

    (* Load by id, load all methods *)
    val load : int64 -> t Lwt.t
    val load_all : unit -> t list Lwt.t

    val save : t -> unit Lwt.t
    val delete : t -> unit Lwt.t

    val to_strings : t -> string list
    val id : t -> int64

(*
    (* Custom loaders *)
    val loaders : (int64 -> t list Lwt.t) array
    val filters : (int64 -> t -> bool) array
*)
  end


type 'a custom_accessor = { get : int64 -> 'a list Lwt.t ;
			     insert : int64 -> 'a -> unit Lwt.t ;
			     remove : int64 -> 'a -> unit Lwt.t ; }

module type DATASTORE =
  sig
    type e
    val get : int64 -> e Lwt.t
    val insert : e -> unit Lwt.t

    val remove : e -> unit Lwt.t (* Lwt.t because we need to catch the mutex *)

    (* Traversal functions *)
    val fold : string -> ('a -> e -> 'a Lwt.t) -> 'a -> 'a Lwt.t
    val fold_indices : string -> ('a -> int64 -> 'a Lwt.t) -> 'a -> 'a Lwt.t
    (* Initialization function *)
    val init : unit -> unit Lwt.t

  (* Custom indicies caches *)
(*    val custom : e custom_accessor array *)
    val custom_insert : int64 -> e -> unit Lwt.t (* Caution : this one insert in all relevant caches in parallel *)

 (* Register callbacks *)
  val register_callback : (unit -> unit Lwt.t) -> unit

    val make_custom_accessor :
      (int64 -> e -> bool) -> e custom_accessor

  end

module type DATABASEFUNCTOR = functor (Data: DATA) ->
  DATASTORE with type e = Data.t

(** Datastore functor *)
module Make : DATABASEFUNCTOR = functor (Data : DATA) ->
struct
  type e = Data.t

  (* Labels *)
  module Label =
    struct
      type t = { id : int64  ; labels : string list }
      let to_strings t = t.labels

    end

  (* The Ptree is used for fast labelled data retrieveal (eg units, individuals, etc ..) *)
  (* For the aficionados : implement a variant of the KMP algorithm *)
  module Ptree = Hygears_ptree.Factory.Make ( Label )

  (* Cache is handled by the Ocsigen_cache module *)
  module OcsigenCache =
    Ocsigen_cache.Make (
      struct
	type key = int64
	type value = Data.t
      end )

  (* mtx protecs access to the ptree *)
  let mtx = Lwt_mutex.create ()

  (* Ptree keeps indicies in memory *)
  let ptree = ref (Ptree.empty)

  (* Callbacks, to trigger side effects when the ptree is updated (for the paginator ..) *)
  let callbacks = ref ([])

  (* Cache only keeps a few values in memory for fast access *)
  let cache = new OcsigenCache.cache Data.load Params.std_cache_size

  (********************************************************)
  (* DATA UPDATE FUNCTIONS                                *)
  (********************************************************)

  (* Morally, we need a mtx only when we update the ptree reference *)
  let get id =
    try
      return (cache#find_in_cache id)
    with Not_found ->
      Data.load id
      >>= fun value -> (* Lwt_mutex.lock mtx
      >>= fun _ -> ptree := Ptree.insert ~replace:true { Label.id = Data.id value ; Label.labels = Data.to_strings value } !ptree ;
                   Lwt_list.iter_s (function f -> f ()) !callbacks
		   >>= fun _ -> Lwt_mutex.unlock mtx ; *) cache#add id value ; return value

  let insert value =
    Lwt_mutex.lock mtx
      >>= fun _ -> ptree := Ptree.insert ~replace:true { Label.id = Data.id value ; Label.labels = Data.to_strings value } !ptree ;
                   Lwt_list.iter_s (function f -> f ()) !callbacks
                   >>= fun _ -> Lwt_mutex.unlock mtx ; cache#add (Data.id value) value ; return ()

  (* Remove an element from both the ptree and the cache *)
  let remove_from_cache id = cache#remove

  let remove_from_ptree e =
    Lwt_mutex.lock mtx
    >>= fun _ -> ptree := Ptree.remove e !ptree ;
                 Lwt_list.iter_s (function f -> f ()) !callbacks
		 >>= fun _ -> Lwt_mutex.unlock mtx ; return ()

  let remove value =
    Lwt_mutex.lock mtx
    >>= fun _ ->
    ptree := Ptree.remove { Label.id = Data.id value ; Label.labels = Data.to_strings value } !ptree ;
             Lwt_list.iter_s (function f -> f ()) !callbacks
             >>= fun _ -> Lwt_mutex.unlock mtx ; return ()


  (********************************************************)
  (* SAFE DATA ACCESS                                     *)
  (********************************************************)

  (* Here is a simple cbl handler that perfoms a safe operation on a value.*)
  (*
    let app_mtx = Lwt_mutex.create ()
    let operate id clb =
    catch
    (fun () -> get id >>= fun value -> clb)
    (function ... | exn -> fail exn)
  *)

  (********************************************************)
  (* TRAVERSAL FUNCTIONS                                  *)
  (********************************************************)

  (* We fold over the ptree + filter in a non cooperative manner, and we cooperatively operate the function *)
  let fold filter f init =
    let subtree = Ptree.search filter !ptree in
    let elist = Ptree.fold (fun acc e ->  e :: acc) [] subtree in
    Lwt_list.fold_left_s (fun acc l -> get l.Label.id >>= fun e -> f acc e) init elist

  let fold_indices filter f init =
    let subtree = Ptree.search filter !ptree in
    let elist = Ptree.fold (fun acc e ->  e :: acc) [] subtree in
    Lwt_list.fold_left_s (fun acc l -> f acc l.Label.id) init elist

  (* We fold over the ptree in a lwt cooperative manner *)
  let fold_lwt _ = assert false


  (********************************************************)
  (* INIT FUNCTIONS                                       *)
  (********************************************************)

  let init () =
    Data.load_all ()
    >>= Lwt_list.iter_s insert


  (********************************************************)
  (* CUSTOM ACCESSORS (bypass the query optimizer) ;(     *)
  (********************************************************)

  let custom_accessors = ref []

  let make_custom_accessor custom_filter =
    let custom_cache = ref Int64Map.empty in
      custom_accessors := (custom_filter, custom_cache) :: !custom_accessors;
    let getter id =
      Printf.fprintf stderr "getter %Ld\n%!" id;
      let list_of_set set =
	Int64Set.elements set >>> Lwt_list.fold_left_s ( fun acc id -> get id >>= fun value -> value :: acc >>> return ) []
      in
	  try
	    list_of_set (Int64Map.find id !custom_cache)
	  with Not_found ->

(*Fabrice TODO: we do not need the vlist result anymore, since we use
the list_of_set function. We use it instead of vlist because it returns
a different result from list_of_set, and it is strange for the user
to have the list changing like that. *)
	    let vlist = Ptree.fold (fun acc e -> e.Label.id :: acc) [] !ptree in
	      Lwt_list.fold_left_s (fun (vlist, cset) e ->
				      get e >>= fun e ->
					match custom_filter id e with
					  | true -> return ((e::vlist), (Int64Set.add (Data.id e) cset))
					  | false -> return (vlist, cset)) ([], Int64Set.empty) vlist
	      >>= fun (vlist, cset) ->
		custom_cache := Int64Map.add id cset !custom_cache;
		list_of_set cset
      in

    let inserter id value =
       let value_id = Data.id value in
       ptree := Ptree.insert ~replace:true { Label.id = value_id ; Label.labels = Data.to_strings value } !ptree ;
       Lwt_list.iter_s (function f -> f ()) !callbacks
       >>= fun _ ->
       custom_cache := Int64Map.add id
	 (Int64Set.add value_id
	    (try Int64Map.find id !custom_cache
	     with Not_found -> Int64Set.empty)) !custom_cache ;
       cache#add (Data.id value) value ; return () in


    let remover id value =
        let value_id = Data.id value in
        (* Lwt_mutex.lock mtx
                >>= fun _ ->
                ptree := Ptree.remove { Label.id = value_id ; Label.labels = Data.to_strings value } !ptree ;
          Lwt_list.iter_s (function f -> f ()) !callbacks
          >>= fun _ ->
                Lwt_mutex.unlock mtx ;
                cache#remove value_id ; *)
        custom_cache := Int64Map.add id
	  (Int64Set.remove value_id
	     (try Int64Map.find id !custom_cache
	      with Not_found -> Int64Set.empty)) !custom_cache;
        Lwt_list.iter_s (function f -> f ()) !callbacks

      in
    { get = getter; insert = inserter; remove = remover }


(*
  (* We keep for each key a set of indicies *)
  let custom_maps = Array.map (fun _ -> Int64Map.empty) Data.loaders
*)

  (* Here we create the custom accessors *)
  (* TODO david : mettre à jour toutes les custom_maps en même temps en fonction du filtre *)
(*
  let custom = Array.mapi (fun i custom ->
			     make_custom_accessor custom)
    Data.filters
*)

  let custom_insert id value =
    Lwt_mutex.lock mtx
    >>= fun _ -> let value_id = Data.id value in
      cache#add value_id value ;
      ptree := Ptree.insert ~replace:true
	{ Label.id = value_id ;
	  Label.labels = Data.to_strings value } !ptree ;

      Lwt_list.iter_s
	(fun (custom_filter, custom_cache) ->
	   let set = try
	     Int64Map.find id !custom_cache
	   with Not_found -> Int64Set.empty
	   in
	     custom_cache := Int64Map.add id
	       (if custom_filter id value then
		  Int64Set.add value_id set
		else
		  Int64Set.remove value_id set)
	       !custom_cache;
	     return ()
	) !custom_accessors
      >>= fun _ -> Lwt_list.iter_s (function f -> f ()) !callbacks

	>>= fun _ -> Lwt_mutex.unlock mtx ; return ()




  (********************************************************)
  (* MANAGE CALLBACKS                                     *)
  (********************************************************)

  let register_callback f =
    callbacks := f :: !callbacks
end


