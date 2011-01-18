open Lwt
open Memcache

(*
module type PARAMS =
  sig
    val cache_size : int
    val page_size : int
  end
*)

type ('key, 'data) paginator = {
  mutable cache_size : int;
  mutable page_size : int;
  cache : ('key, 'data) Memcache.cache;
}

let create ?(cache_size=10) ?(page_size=10) data_create =

  let entries_from_key key =
    data_create key >>= fun list ->
      return (Array.of_list list)
  in
  let cache = Memcache.cache_create cache_size entries_from_key in
    {
      cache_size = cache_size;
      page_size = page_size;
      cache = cache;
    }


let get_page t ?(page_size=t.page_size) key page_id =
  cache_find t.cache key >>= fun entries ->
    let nentries = Array.length entries in
    let page_size =
      if page_size < 1 then 1 else
      if page_size > nentries then nentries else page_size
    in
    return
	(if nentries = 0 then
	   (0,0,0, []) (* nentries, npages, page, values *)
	 else
	   let last_page = (nentries - 1) / page_size in
	   let page_id =
	     if page_id < 0 then 0 else
	       if page_id > last_page then last_page else
		 page_id
	   in
	   let pos = page_id * page_size in
	   let next_pos = pos + page_size in
	   let next_pos = if next_pos > nentries then nentries else next_pos
	   in
	     (nentries, last_page+1, page_id,
	      Array.to_list (Array.sub entries pos (next_pos - pos)))
	)

let clean t key =
  cache_remove t.cache key

let clear t =
  cache_clear t.cache
