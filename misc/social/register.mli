(* These registration functions are used to check the current user and
   provide the user profile to the final handler. They can also check if
   a user has administrative rights. *)

(* Don't forget to set the default pages *)


val no_cache : Http_headers.t

(* [set_anonymous_default_page f] sets [f] as the function to be
   called with an [uri option] that should return the page
   to which redirect when a profile is expected and the user
   is not logged in. *)
val set_anonymous_default_page :
  (string option -> Eliom_predefmod.Redirection.page) -> unit

(* [set_profile_default_page f] sets [f] as the function to be called
   with the profile of the current user that should return the
   home page to which redirect the user in case of error. *)
val set_profile_default_page :
  (Profile.profile -> Eliom_predefmod.Redirection.page) -> unit


val register_json :
  ('a, 'b, [< Eliom_services.internal_service_kind ],
   [< Eliom_services.suff ], 'c, 'd, [ `Registrable ])
  Eliom_services.service ->
  (Eliom_sessions.server_params ->
     Profile.profile -> 'a -> 'b -> Json_type.t Lwt.t) ->
  unit

val register_safe :
  ?anonymous:(Eliom_sessions.server_params ->
                'a -> 'b -> Eliom_predefmod.Any.page Lwt.t)
  option ->
  ?restrict:bool ->
  ('a, 'b, [< Eliom_services.internal_service_kind > `Attached ],
   [< Eliom_services.suff ], 'c, 'd, [ `Registrable ])
    Eliom_services.service ->
  (Eliom_sessions.server_params ->
     Profile.profile -> 'a -> 'b -> Eliom_predefmod.Any.page Lwt.t) ->
  unit

val register_admin :
  ?anonymous:(Eliom_sessions.server_params ->
                'a -> 'b -> Eliom_predefmod.Any.page Lwt.t)
  option ->
  ('a, 'b, [< Eliom_services.internal_service_kind ],
   [< Eliom_services.suff ], 'c, 'd, [ `Registrable ])
    Eliom_services.service ->
  (Eliom_sessions.server_params ->
     Profile.profile -> 'a -> 'b -> Eliom_predefmod.Any.page Lwt.t) ->
  unit

val register_unsafe :
  ('a, 'b, [< Eliom_services.internal_service_kind ],
   [< Eliom_services.suff ], 'c, 'd, [ `Registrable ])
  Eliom_services.service ->
  (Eliom_sessions.server_params ->
     'a -> 'b -> Eliom_predefmod.Any.page Lwt.t) ->
  unit

val register_json_admin :
  ('a, 'b, [< Eliom_services.internal_service_kind ],
   [< Eliom_services.suff ], 'c, 'd, [ `Registrable ])
  Eliom_services.service ->
  (Eliom_sessions.server_params ->
     Profile.profile -> 'a -> 'b -> Json_type.t Lwt.t) ->
  unit
