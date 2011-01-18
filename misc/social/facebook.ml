(*
* club des juristes
*
* facebook.ml - home page
*
* Fabrice Le Fessant <fabrice@ocamlpro.com>
*)

open Lwt
open XHTML.M
open Misc

let graph_get ~uri =
  Ocsigen_lib.get_inet_addr "graph.facebook.com" >>= fun inet_addr ->
    Ocsigen_http_client.raw_request
      ~content:None
      ~http_method:Ocsigen_http_frame.Http_header.GET
      ~https:true
      ~inet_addr
      ~host:"graph.facebook.com"
      ~uri
      ()
      ()
    >>= fun frame ->
      match frame.Ocsigen_http_frame.frame_content with
          None -> failwith "Server down"
        | Some data ->
	    Ocsigen_stream.string_of_stream (Ocsigen_stream.get data)

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

let facebook_me = {
  fb_me_id =  "";
  fb_me_name =  "";
  fb_me_first_name =  "";
  fb_me_middle_name =  "";
  fb_me_last_name =  "";
  fb_me_link =  "";
  fb_me_gender =  "";
  fb_me_timezone =  0;
  fb_me_locale =  "";
  fb_me_verified =  false;
  fb_me_updated_time =  "";
}

let facebook_of_json j =
  match j with
      Json_type.Object list ->
	let me = { facebook_me with fb_me_timezone = 0; } in
	  List.iter (fun (s,v) ->
		       let s = String.lowercase s in
			 match s, v with
			   | "id", Json_type.String s -> me.fb_me_id <- s
			   | "name", Json_type.String s -> me.fb_me_name <- s
			   | "first_name", Json_type.String s -> me.fb_me_first_name <- s
			   | "middle_name", Json_type.String s -> me.fb_me_middle_name <- s
			   | "last_name", Json_type.String s -> me.fb_me_last_name <- s
			   | "link", Json_type.String s -> me.fb_me_link <- s
			   | "gender", Json_type.String s -> me.fb_me_gender <- s
			   | "timezone", Json_type.Int s -> me.fb_me_timezone <- s
			   | "locale", Json_type.String s -> me.fb_me_locale <- s
			   | "verified", Json_type.Bool b -> me.fb_me_verified <- b
			   | "updated_time", Json_type.String s -> me.fb_me_updated_time <- s
			   | _, _ ->
			       debug' "Discarding %s" s
		    ) list;
	  me
    | _ -> failwith "facebook_of_json: not an object"

module FBConnect(FBConfig : sig

		   val error_handler :
		     Eliom_sessions.server_params -> Json_type.json_type -> Eliom_predefmod.Xhtml.page Lwt.t
		   val connect_handler :
		     Eliom_sessions.server_params -> access_token: string -> facebook_me -> Eliom_predefmod.Xhtml.page Lwt.t

		   val service_path : string list
		   val app_id : string
		   val app_secret : string

		 end) = struct


  open Eliom_parameters

  let facebook_service = Eliom_services.new_service
    ~path: FBConfig.service_path
    ~get_params:(string "code")
    ()

  let redirect_uri sp =
    let (redirect_uri, _, _) =
      Eliom_predefmod.Xhtml.make_uri_components
	~absolute_path: true
	~sp
	~service: facebook_service
	""
    in
    let port = Eliom_sessions.get_server_port sp in
      Printf.sprintf "http://%s%s%s"
	(Eliom_sessions.get_hostname sp)
	(if port = 80 then "" else Printf.sprintf ":%d" port)
	redirect_uri

  let rec facebook_handler sp code _ =

    let uri = Printf.sprintf "/oauth/access_token?client_id=%s&client_secret=%s&redirect_uri=%s&code=%s"
      FBConfig.app_id FBConfig.app_secret
      (redirect_uri sp)
      code
    in
      graph_get uri >>=
	fun r ->
	  let args = Netencoding.Url.dest_url_encoded_parameters r in
	  let access_token = List.assoc "access_token" args in
	    graph_get
	      (Printf.sprintf "/me?access_token=%s" access_token)
	    >>= fun r ->
	      (*	    let r = Json_io.string_of_json ~compact:false j in *)
	      let j = Json_io.json_of_string r in
		match j with
		    Json_type.Object [ "error", reason ] ->
		      FBConfig.error_handler sp reason
		  | _ ->
		      let me = facebook_of_json j in
			FBConfig.connect_handler sp access_token me

  let _ =
    Eliom_predefmod.Xhtml.register facebook_service facebook_handler

  let fb_connect_url sp = Printf.sprintf
    "https://graph.facebook.com/oauth/authorize?client_id=%s&redirect_uri=%s"
    FBConfig.app_id (redirect_uri sp)

end
