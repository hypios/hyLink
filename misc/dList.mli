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

(** Doubly-linked lists with maximum size. *)
  type 'a t
  type 'a node
  val create : unit -> 'a t
  val create_bounded : int -> 'a t

  (** Adds an element to the list,
      and possibly returns the element that has been removed if the maximum
      size was exceeded. *)
  val add : 'a -> 'a t -> 'a option

  (** Removes an element from its list.
      If it is not in a list, it does nothing.
      If it is in a list, it calls the finaliser, then removes the element.
      If the finaliser fails with an exception,
      the element is removed and the exception is raised again.
  *)
  val remove : 'a node -> unit

  (** Removes the element from its list without finalising,
      then adds it as newest. *)
  val up : 'a node -> unit

  val newest : 'a t -> 'a node option
  val oldest : 'a t -> 'a node option

  val size : 'a t -> int
  val maxsize : 'a t -> int
  val value : 'a node -> 'a

  (** The list to which the node belongs *)
  val list_of : 'a node -> 'a t option

  (** remove the n oldest values (or less if the list is not long enough) ;
      returns the list of removed values *)
  val remove_n_oldest : 'a t -> int -> 'a list

  (** change the maximum size ;
      returns the list of removed values, if any.
  *)
  val set_maxsize : 'a t -> int -> 'a list

  (** set a function to be called automatically on a piece of data
      just before it disappears from the list
      (either by explicit removal or because the maximum size is exceeded) *)
  val set_finaliser : ('a node -> unit) -> 'a t -> unit
  val get_finaliser : 'a t -> ('a node -> unit)

