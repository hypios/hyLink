(** *)

type 'a id = int64

let type_of_id = Type.Int (Some 64);;
let value_of_id ~id_seed x = Value.Int x;;
let id_of_value = function Value.Int x -> x | _ -> assert false;;

let id_funs = (type_of_id, value_of_id, id_of_value)

