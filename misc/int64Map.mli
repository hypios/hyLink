(** Map with 64-bits integers as keys. *)

include Map.S with type key = Int64.t

(** [int64map_partial_fold lim f map init] applies [f] on elements of [map]
  until [lim] elements have been handled or [f] returns [false] as second
  part of its return value. *)
val int64map_partial_fold :
  int -> (key -> 'a -> 'b -> 'b * bool) -> 'a t -> 'b -> 'b

(** [int64map_paginated_fold ~from ~size f map init]
  works as {!int64map_partial_fold} but starts from [from] indice. *)
val int64map_paginated_fold :
  from: int -> size: int ->
   (key -> 'a -> 'b -> 'b * bool) -> 'a t -> 'b -> 'b
