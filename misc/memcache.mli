(* Ocsimore
 * Copyright (C) 2008
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
Association tables (from any kind of database)
that keep the most recently used values in memory.

It is based on a structure of doubly linked lists with maximum size,
that keeps only the mostly recently used values first, if you call the [up]
function each time you use a value.
(Insertion, remove and "up" in time 1).
This structure is exported, so that it can be used in other cases.

Not (preemptive) thread safe.

@author Vincent Balat
*)


(* This is supposed to replace Ocsigen_cache as a non-functor version *)
type ('a, 'b) cache

val cache_clear : ('a, 'b) cache -> unit
val cache_create : int -> ('a -> 'b Lwt.t) -> ('a, 'b) cache

val find_in_cache : ('a, 'b) cache -> 'a -> 'b
val cache_remove : ('a, 'b) cache -> 'a -> unit
val cache_add_no_remove : ('a, 'b) cache -> 'a -> 'b -> unit
val cache_add : ('a, 'b) cache -> 'a -> 'b -> unit
val cache_size : ('a, 'b) cache -> int
val cache_find : ('a, 'b) cache -> 'a -> 'b Lwt.t

(** Clear the contents of all the existing caches *)
val clear_all_caches : unit -> unit

(* These functions mimic Hygears_cache functions *)
(* val cache_get --> would be cache_find *)
val cache_update :
  ('key, 'data) cache ->
           ('key -> 'c -> 'data -> 'data Lwt.t) -> 'key -> 'c -> 'data Lwt.t
val cache_insert :
  ('key, 'data) cache -> ('c -> 'data -> 'key Lwt.t) -> 'c -> 'data -> unit Lwt.t
