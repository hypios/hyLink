(* Ocsigen
 * Copyright (C) 2008-2009
 * Laboratoire PPS - Université Paris Diderot - CNRS
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(**
Cache.

@author Vincent Balat
*)

let (>>=) = Lwt.bind
let return = Lwt.return

module Weak =  Weak.Make(struct type t = unit -> unit
                                let hash = Hashtbl.hash
                                let equal = (==)
                         end)

let clear_all = Weak.create 17

(*
module Make =
  functor (A: sig
             type key
             type value
           end) ->
struct
*)
type ('key, 'value) cache =
      { mutable pointers : 'key DList.t;
        mutable table : ('key, 'value * 'key DList.node) Hashtbl.t;
        finder : 'key -> 'value Lwt.t;
        clear: unit -> unit (* This function clears the cache. It is put inside the
          cache structure so that it is garbage-collected only when the cache
          is no longer referenced, as the functions themselves are put inside
          a weak hash table *)
      }

  let cache_clear cache =
    let size = DList.maxsize cache.pointers in
    cache.pointers <- DList.create_bounded size;
    cache.table <- Hashtbl.create size

  let cache_create size f =
    let rec cache = {pointers = DList.create_bounded size;
                     table = Hashtbl.create size;
                     finder = f;
                     clear = f_clear;
                    }
    and f_clear = (fun () -> cache_clear cache)
    in
    Weak.add clear_all f_clear;
    cache

  (* not exported *)
  let poke cache node =
    assert (match DList.list_of node with
              | None -> false | Some l -> cache.pointers == l);
    DList.up node

  let find_in_cache cache k =
    let (v, node) = Hashtbl.find cache.table k in
    poke cache node;
    v

  let cache_remove cache k =
    try
      let (_v, node) = Hashtbl.find cache.table k in
      Hashtbl.remove cache.table k;
      assert (match DList.list_of node with
                | None -> false | Some l -> cache.pointers == l);
      DList.remove node
    with Not_found -> ()

  (* Add in a cache, under the hypothesis that the value is
     not already in the cache *)
  let cache_add_no_remove cache k v =
    (match DList.add k cache.pointers with
      | None -> ()
      | Some v -> Hashtbl.remove cache.table v
    );
    match DList.newest cache.pointers with
      | None -> assert false
      | Some n -> Hashtbl.add cache.table k (v, n)

  let cache_add cache k v =
    cache_remove cache k;
    cache_add_no_remove cache k v

  let cache_size c =
    DList.size c.pointers

  let cache_find cache k =
    (try
       Lwt.return (find_in_cache cache k)
     with Not_found ->
       cache.finder k >>= fun r ->
       (try (* it may have been added during cache.finder *)
          ignore (find_in_cache cache k)
        with Not_found -> cache_add_no_remove cache k r);
       Lwt.return r)

(*
  class cache f size_c =
    let c = create f size_c in
  object
    method clear () = clear c
    method find = find c
    method add = add c
    method size = size c
    method find_in_cache = find_in_cache c
    method remove = remove c
  end
*)

(*
end
*)

let clear_all_caches () = Weak.iter (fun f -> f ()) clear_all

open Lwt

let cache_update t update key diff =
  cache_find t key >>=
    update key diff >>= fun updated_value ->
      cache_remove t key ;
      cache_add t key updated_value ; return updated_value

let cache_insert t insert key value =
  insert key value >>= fun new_key -> return (cache_add t new_key value)
