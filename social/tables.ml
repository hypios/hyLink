(*
 * hyLink - fpgg
 *
 * tables.ml - session tables
 *
 * William Le Ferrand william@myrilion.com
 *
 *)

open Lwt

open Eliom_sessions

open Misc
open Profile

let profiles: profile volatile_table = create_volatile_table ()

let get_profile sp : profile option Lwt.t =
  get_volatile_session_data ~table:profiles ~sp ()
  >>> function
    | Data d -> return (Some d)
    | _ -> return None ;;

let set_profile sp profile =
  debug' "@@@ Setting profile\n" ;
  debug' "%Ld" profile.profile_id;
  set_volatile_session_data ~table:profiles ~sp profile >>> return

let remove_profile sp =
  remove_volatile_session_data ~table:profiles ~sp () >>> return

let update_profile sp profile =
  set_volatile_session_data ~table:profiles ~sp profile >>> return

