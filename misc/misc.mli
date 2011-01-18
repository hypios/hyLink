(** *)

(** {2 General} *)

(** The bind operator *)
val ( >>> ) : 'a -> ('a -> 'b) -> 'b

(** Immediately print out a message on standard output, or do nothing.
Modify the code to suit your needs. *)
val debug' : ('a, unit, string, unit) format4 -> 'a

(**  Adds [,] characters to pretty-print the given number (as string). *)
val pretty_print_number : string -> string

(** {2 Date an time} *)


(** Generate a float-like string timestamp from current date and time. *)
val timestamp : unit -> string

val pretty_print_date : CalendarLib.Printer.Date.t -> string

(** {2 Ocisgen/Lwt utilities} *)

type flows = Xhtmltypes.div_content XHTML.M.elt list

(** Make ocsigen write a warning message in the log. *)
val warning : ('a, unit, string, unit) format4 -> 'a

(** Make ocsigen write an error message in the log. *)
val error : ('a, unit, string, unit) format4 -> 'a

(** Guess what ? *)
val array_fold_left_lwt :
  ('a -> 'b -> 'a Lwt.t) -> 'a -> 'b array -> 'a Lwt.t

(** Guess what ? *)
val iteri_lwt : (int -> 'a -> 'b Lwt.t) -> 'a array -> unit Lwt.t

(** Opening a file in append mode with [Lwt].*)
val open_append_lwt : Lwt_io.file_name -> Lwt_io.output Lwt_io.channel Lwt.t

(** {2 Using Mysql} *)

val extract_result :
  (string option array -> 'a) ->
  (Mysql.result -> 'a list) -> Mysql.result -> 'a list

(** Recursive terminal. *)
val fold_result :
  (string option array -> 'a -> 'a) -> Mysql.result -> 'a -> 'a

val fold_result_b :
  (string option array -> 'a -> 'a) -> 'a -> Mysql.result -> 'a Lwt.t
val fold_result_lwt :
  (string option array -> 'a -> 'a Lwt.t) -> Mysql.result -> 'a -> 'a Lwt.t
val fold_result_lwt_b :
  (string option array -> 'a -> 'a Lwt.t) -> 'a -> Mysql.result -> 'a Lwt.t

val date2ml : string -> CalendarLib.Date.t

(** {2 Convenient modules.} *)

(** Ordered integers. *)
module Int : Map.OrderedType with type t = int

(** Revert-ordered strings. *)
module ReverseString : Map.OrderedType with type t = string

(** Maps with integer keys. *)
module IntMap : Map.S with type key = int

(** Maps with revert-ordered strings. *)
module StringMap : Map.S with type key = string

(** Revert-ordered characters. *)
module InversedChar : Map.OrderedType with type t = char

(** Map with revert-ordered characters as keys. *)
module CharMap : Map.S with type key = InversedChar.t

(** {2 String utils} *)

(** Split the given string according to [,] character with or without
  blanks before and after.*)
val comma_split : string -> string list

(** [condense_string s n] returns [s] if its length is <= n or else
  [(String.sub s 0 m) ^ "..."], with m begin [String.lengh s - 3].
  That is, the returned string has a amximum length of [n]. *)
val condense_string : string -> int -> string

(** convert the given string to utf8 encoding
  (from ISO88591). *)
val convert_to_utf8 : string -> string

(** [trim_beginning s] returns a new string where the spaces at the beginning
  of [s] have been removed. *)
val trim_beginning : string -> string

(** [trim_end s] returns a new string where the spaces at the end
  of [s] have been removed. *)
val trim_end : string -> string

(** [trim s = trim_beginning (trim_end s)]. *)
val trim : string -> string

val extract_address_simple : string -> string

val extract_address_cedex : string -> string

(*i==v=[String.first_sentence]=1.0====*)
(** [first_sentence ?limit s] returns the first sentence of [s], in the limit
   of [limit] characters. By default, this limit is 40..
   A sentence is terminated by a dot followed by a blank.
@author Maxence Guesdon
@version 1.0
@cgname String.first_sentence*)
val first_sentence : ?limit:int -> string -> string
(*/i==v=[String.first_sentence]=1.0====*)

(** [opt_string ?default] (Some s) returns [s].
   [opt_string ?default] None returns the default string. Default default string is [""].*)
val opt_string : ?default: string -> string option -> string

(** {2 List utils} *)

(** Merge two string lists: first order the two lists with [String.compare]
  then use [List.merge]. *)
val merge_string_lists : String.t list -> String.t list -> String.t list

(** Merge the given two lists, removing duplicate values (only one is kept).
  [List.mem] is used to detect duplicate values.*)
val merge_list_without_duplicate : 'a list -> 'a list -> 'a list

(** [filter_list l1 l2] returns the elements from list [l2] which do not
  appear in [l1].
  @param pred can be used to specify the comparison function.
  Default function is [=]. *)
val filter_list :
  ?pred: ('a -> 'a -> bool) ->
   'a list -> 'a list -> 'a list

(** [extract_partial n l] returns the [n] first elements of [l], or the
  whole list is its length is less or equal to [n].
  No tail-recursrive.*)
val extract_partial : int -> 'a list -> 'a list

(** {2 Are these functions useful ?} *)

val fresh_id_project : unit -> int Lwt.t
