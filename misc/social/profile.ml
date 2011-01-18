(*
* club des juristes
*
* profile.ml
*
* Simon Marc <marc.simon42@gmail.com>
*)

include Account_type

type profile =
    {
        profile_id:                 int64 ;
        mutable profile_type: account_type ;
(*        mutable current_profile_list: int64 list ; (* for profil page, several tabs *) *)
    }

(** Returns true if the connected user is an administrator *)
let is_admin profile =
  profile.profile_type == admin_account

(*
with orm

module Profile_persistent =
    struct

    let db = profile_init Params.sqlite_db

    let get_profile_by_id user_id =
        Lwt_preemptive.detach (fun () -> profile_get_by_id ~id:(`Eq user_id) db) ()

    let save profile =
        Lwt_preemptive.detach (fun profile -> profile_save ~db profile true) profile

    let delete profile =
        Lwt_preemptive.detach ( profile_delete ~db ) profile
end

*)



