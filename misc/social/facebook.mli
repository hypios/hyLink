
(* The identity of the user on facebook.com *)
type facebook_me = {
  mutable fb_me_id : string;
  mutable fb_me_name : string;
  mutable fb_me_first_name : string;
  mutable fb_me_middle_name : string;
  mutable fb_me_last_name : string;
  mutable fb_me_link : string;
  mutable fb_me_gender : string;
  mutable fb_me_timezone : int;
  mutable fb_me_locale : string;
  mutable fb_me_verified : bool;
  mutable fb_me_updated_time : string;
}

(* This functor creates the Eliom service that will receive the
   redirection from Facebook once the user is authentified. *)
module FBConnect :
  functor
    (FBConfig : sig

       (* Your Application ID *)
       val app_id : string

       (* Your Application Secret *)
       val app_secret : string

       (* The path in your Eliom site of the redirection URL (e.g. [ "facebook"]) *)
       val service_path : string list

      (* A function to be called when there is an error of authentication *)
       val error_handler :
         Eliom_sessions.server_params ->
         Json_type.json_type -> Eliom_predefmod.Xhtml.page Lwt.t

       (* A function to be called when the authentication
	  succeeded. The access_token is given as an argument, and the
	  facebook record for the user too. *)
       val connect_handler :
         Eliom_sessions.server_params -> access_token: string ->
         facebook_me -> Eliom_predefmod.Xhtml.page Lwt.t
     end) ->
sig
  (* The URL to facebook for authentication. It contains
     parameters used to redirect to this site. *)
  val fb_connect_url : Eliom_sessions.server_params -> string
end

      (** Misc *)

      (* A function to access the graph.facebook.com website. It
	 requires an uri with an access_token parameter set (for
	 example, /me?access_token=.... ), and returns the content as
	 a string (to be parsed as JSON).  *)

val graph_get : uri: string -> string Lwt.t
