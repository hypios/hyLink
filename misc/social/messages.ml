(**

*)

open Types;;

module type S =
  sig
    type author_id

    type message =
      {
       message_author : author_id ;
       message_content : string ;
       message_time : time ;
      }

    include Ids.Orm_out with type t = message

    module Basic : PersistentFunctor.CELT with type t = message
  end

module type P = sig module Author : Ids.Orm_out end

module Make (P: P) = struct
  open P.Author
  type author_id = t with orm;;

  type message =
    {
     message_author : author_id ;
     message_content : string ;
     message_time : time ;
    } with orm

  module Mes = struct
    type t = message with orm
  end

  include Mes

  module Basic = struct
    type t = message
    let init = Mes.t_init
    let get_by_id = Mes.t_get_by_id
    let id = Mes.t_id
    let get custom db = Mes.t_get db
    let save = Mes.t_save
    let delete = Mes.t_delete
    let search = Mes.t_search
    end
end