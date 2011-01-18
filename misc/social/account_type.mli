
type account_type

val new_account_type : string -> account_type

val string_of_account : account_type -> string
val account_of_string : string -> account_type
val int_of_account : account_type -> int
val account_of_int : int -> account_type

(* We define account types using an abstract type "account", that we
   can convert to and from strings and ints. Account types are defined
   using the [new_account_type] function. We define only [admin_account]
   in [Profile] as it is the only one needed at this point. Other ones
   are defined in shared/cdj/cdj.ml *)

val admin_account : account_type


val hash_of_account_type : account_type -> int
val type_of_account_type : Type.t

val value_of_account_type :
  id_seed:Orm.Sql_backend.state -> account_type -> Value.t
val account_type_of_value : Value.t -> account_type
