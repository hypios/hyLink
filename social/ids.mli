(**
  Convenient functions when using ORM.

  <OCamlpro>
*)

type 'a id = int64
val type_of_id : Type.t
val value_of_id : id_seed:'b -> 'a id -> Value.t
val id_of_value : Value.t -> 'a id
val id_funs : Type.t * (id_seed:'b -> 'a id -> Value.t) * (Value.t -> 'a id)

