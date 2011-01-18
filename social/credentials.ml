open Misc
open Lwt
open Account_type


type credentials =
    {
      cred_profile_id:              int64 ;
      cred_profile_type :           string;
      mutable cred_email:           string ;
      mutable cred_password_hash:   string ;
      cred_salt:                    string ;
    } with orm

module Security = struct

  let random_char () =
    97 + Random.int 25 >>> char_of_int

  let random_password () =
    let s = String.create 8 in
      for i = 0 to 7 do
	s.[i] <- random_char ()
      done ; s

  let random_salt () =
    let s = String.create 10 in
      for i = 0 to 7 do
	s.[i] <- random_char ()
      done ; s

  let create password =
    let hasher = Cryptokit.Hash.sha1 () in
    let encoder = Cryptokit.Hexa.encode () in
    let salt = random_password () in
    let salted = salt ^ password ^ salt in
    let hashed = Cryptokit.hash_string hasher salted in
    let hashed = Cryptokit.transform_string encoder hashed in
      salt, hashed

  let update credentials password =
    let hasher = Cryptokit.Hash.sha1 () in
    let encoder = Cryptokit.Hexa.encode () in
    let salted = credentials.cred_salt ^ password ^ credentials.cred_salt in
    let hashed = Cryptokit.hash_string hasher salted in
    let hashed = Cryptokit.transform_string encoder hashed in
      credentials.cred_password_hash <- hashed

  let check credentials password =
    let hasher = Cryptokit.Hash.sha1 () in
    let encoder = Cryptokit.Hexa.encode () in
    let salted = credentials.cred_salt ^ password ^ credentials.cred_salt in
    let hashed = Cryptokit.hash_string hasher salted in
    let hashed = Cryptokit.transform_string encoder hashed in
      hashed = credentials.cred_password_hash

  let clone credentials  =
    let hasher = Cryptokit.Hash.sha1 () in
    let encoder = Cryptokit.Hexa.encode () in
    let password = random_password () in
    let salted = credentials.cred_salt ^ password ^ credentials.cred_salt in
    let hashed = Cryptokit.hash_string hasher salted in
    let hashed = Cryptokit.transform_string encoder hashed in
      { credentials with cred_password_hash= hashed } , password

end



module Credentials_persistent = struct

  let db = credentials_init Params.sqlite_db

  let get_user_id email pwd_hash =
    Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_email = email && c.cred_password_hash = pwd_hash)) db

  let get_by_email email password =
     Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_email = email && Security.check c password )) db

 let get_by_user_id_raw user_id =
     Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_profile_id = user_id )) db

  let get_by_user_id user_id pwd_hash =
    Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_profile_id = user_id && c.cred_password_hash = pwd_hash)) db

  let get_by_email_only email =
    Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_email = email)) db

  let save credentials =
    Lwt_preemptive.detach (fun credentials ->credentials_save ~db credentials true) credentials

  let get_by_email_raw email =
    Lwt_preemptive.detach (credentials_get ~custom:(fun c -> c.cred_email = email)) db

  let delete credentials =
    Lwt_preemptive.detach (credentials_delete ~db) credentials
end
