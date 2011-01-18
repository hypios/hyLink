(*
 * club des juristes
 *
 * profile.ml
 *
 * Simon Marc <marc.simon42@gmail.com>
 *)

type account_type = {
  account_name : string;
  account_num : int;
} with orm

let naccounts = ref 0
let accounts_of_string = ref StringMap.empty
let accounts_of_int = Hashtbl.create 13

let new_account_type s =
  let t = {
    account_name = s;
    account_num = !naccounts;
  } in
    incr naccounts;
    accounts_of_string := StringMap.add (String.lowercase s) t
      !accounts_of_string;
    Hashtbl.add accounts_of_int t.account_num t;
    t
let string_of_account t = t.account_name
let account_of_string s =
  StringMap.find (String.lowercase s) !accounts_of_string

let int_of_account t = t.account_num
let account_of_int int = Hashtbl.find accounts_of_int int

(* We define account types using an abstract type "account", that we
can convert to and from strings and ints. Account types are defined
using the [new_account_type] function. We define only [admin_account]
in [Profile] as it is the only one needed at this point. Other ones
are defined in shared/cdj/cdj.ml *)

let admin_account = new_account_type "Admin"
