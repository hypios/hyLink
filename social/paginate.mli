(* A paginator type, that can be used to return results as pages instead
of using the functor from Hygears_paginate. *)

(* The type *)
type ('a, 'b) paginator

(* [create_paginator ~cache_size ~page_size create] creates the
   paginator for a cache of size [cache_size], the default page size
   will be [page_size] and values will be created by [create]. *)

val create :
  ?cache_size:int ->
  ?page_size:int -> ('a -> 'b list Lwt.t) -> ('a, 'b array) paginator

(* [get_page t ~page_size key num_page] returns the page number
   [num_page] of the paginated results associated with key [key] in
   the paginator [t]. The page will contain [page_size] results if
   specified, the default value otherwise. *)

val get_page :
  ('key, 'data array) paginator ->
  ?page_size:int ->
  'key ->
  int ->      (* requested page number *)
  (int        (* total number of replies *)
   * int      (* number of pages *)
   * int      (* returned page number *)
   * 'data list  (* entries *)
  ) Lwt.t

(* [clean t key] cleans the cache of paginator [t] from the values
associated with key [key]. *)
val clean : ('a, 'b) paginator -> 'a -> unit

(* [clear t] cleans the cache of paginator [t] from all its values. *)
val clear : ('a, 'b) paginator -> unit
