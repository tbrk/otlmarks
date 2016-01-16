(* Copyright (c) 2016 Timothy Bourke. All rights reserved. See LICENCE. *)

(** simple html helpers *)

let tagname (tn, _, _) = tn
let contents (_, _, doc) = doc

let istag s e =
  match e with
  | Nethtml.Element (tag, _, _) -> tag = s
  | Nethtml.Data _ -> false

let isheading e =
  match e with
  | Nethtml.Element (tag, _, _) ->
      String.length tag = 2
      && tag.[0] = 'h'
      && '0' <= tag.[1] && tag.[1] <= '9'
  | Nethtml.Data _ -> false

let text (_, _, data) =
  match data with
  | [] -> ""
  | [Nethtml.Data s] -> s
  | _ -> raise Not_found

let ele_triple ele =
  match ele with
  | Nethtml.Element v -> v
  | _ -> assert false
  
let filter f xs = List.map ele_triple (List.filter f xs)
let find f xs = match List.find f xs with
                | Nethtml.Element v -> v
                | _ -> raise Not_found

let attr v (_, ats, _) = List.assoc v ats

(* raises Not_found *)
let rec expect ts doc =
  match ts with
  | [] -> doc
  | t::ts ->
      let (_, _, doc) = find (istag t) doc in
      expect ts doc

let (<||>) f g xs = try f xs with Not_found -> g xs

let rec ffilter f xs =
  match xs with
  | [] -> []
  | x::xs -> try f x :: ffilter f xs with Not_found -> ffilter f xs

(** parse bookmarks *)

type item = { name: string; href: string }
type folder = { name: string; bookmarks: bookmark list }
 and bookmark =
    Folder of folder
  | Item   of item

let parse_item ds =
  let ele = find (istag "a") ds in
  Item { name = text ele; href = attr "href" ele }

let rec parse_folder ds =
  let parse (_, _, xs) = (parse_item <||> parse_folder) xs in
  Folder { name = text (find isheading ds);
           bookmarks =
             let ds' = contents (find (istag "dl") ds) in
             ffilter parse (filter (istag "dt") ds') }

let decode s = Netencoding.Html.decode ~in_enc:`Enc_utf8 ~out_enc:`Enc_utf8 () s

let print_otl fout ele =
  let fprintf = Printf.fprintf in
  let rec indent n =
    if n <= 0 then () else (fprintf fout "\t"; indent (n - 1)) in
  let rec go n x =
    match x with
    | Item { name; href } ->
        indent n; fprintf fout "* %s\n" (decode name);
        indent (n + 1); fprintf fout "; %s\n" href
    | Folder { name; bookmarks } ->
        indent n; fprintf fout "%s\n" (decode name);
        List.iter (go (n + 1)) bookmarks
  in
  fprintf fout "%% vim:ft=votl foldlevel=0\n\n";
  match ele with
  | Folder { bookmarks } -> List.iter (go 0) bookmarks
  | _ ->  assert false

let from_chrome fin =
  let ch = new Netchannels.input_channel fin in
  let doc = Nethtml.((parse ~dtd:relaxed_html40_dtd ch : document list)) in
  print_otl stdout (parse_folder doc)
;;

if Array.length Sys.argv = 0
then from_chrome stdin
else from_chrome (open_in Sys.argv.(1));;

