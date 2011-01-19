(*
 * hyLink - fpgg 
 *
 * params.ml - parameters
 *
 * William Le Ferrand william@hypios.com
 * 
 *)

open Simplexmlparser

let config = 
  List.fold_left (fun acc e -> 
		    match e with
			Element(k, _ , PCData (v) :: _) ->
			  (k,v) :: acc
		      | _ -> acc)
    [] (Eliom_sessions.get_config ())
    

let fetch e = 
  try List.assoc e config with _ -> Printf.printf "Parameter %s is missing\n" e; flush stdout ; exit (-1)

let prefix = fetch "prefix" 
let public_dir = fetch "public-dir"
let private_dir = fetch "private-dir"

(* Network page length *)
let page_length = 15
let json_length = 10

(* Mysql params *)
let mysql_pool_size = 5 
let mysql_login = fetch "mysql-login"
let mysql_pwd = fetch "mysql-pwd"
let mysql_host = fetch "mysql-host"
let mysql_dbname = fetch "mysql-dbname"

(* Sqlite params *)
let sqlite_db = fetch "fpgg-db" 
let db_wiki = fetch "wiki-db"

(* Zementa *)
let zemanta_pool_size = 2
let zemanta_api_key = fetch "zemanta-api-key" 

(* Cache size *)
let std_cache_size = int_of_string (fetch "cache-size")

(* Display parameters / Activities *)
let number_of_challenges = 10
let number_of_projects = 10

(* cache size for thread and message *)
let size_for_thread = 3000
let size_for_message = 3000

(* Gmail parameters *)

let mailing_name = "Fpgg-network"
let mailing_user = "staging@fpgg-network.org"
let mailing_password = "hypios2509"
let mailing_timeout = 10.0

(* Feed depth *)
let feed_depth = 10 
let feed_depth_delta = 10 

let nb_followers_overview = 3
let nb_following_overview = 3
let nb_projects_overview = 3
let nb_labs_overview = 3


(* Webmaster contact info *)
let webmaster_email = "bugs@fpgg-network.org"

(***********************************************************)
(* SQLITE dababases files                                  *)
(***********************************************************)

(* Paginator *)
let paginate_size = 2500
let page_size = 10
let paginate_delta = 4
let agenda_page_size = 4
let publication_page_size = 3

let institution_page_size = 4
let lab_page_size = 5


(* Publications *)
let excerpt_size = 200

(* Graph cache *)
let graph_cache_size = 4500
let graph_poll_result_file = fetch "poll-result-file"

(* Imagemagick binary *)

let imagemagick = fetch "imagemagick-convert"

let host = fetch "host" 


(* Skills suggestions *)
let skills_suggestion_card = 7 
