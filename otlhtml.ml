(* Copyright (c) 2016 Timothy Bourke. All rights reserved. See LICENCE. *)

type item = { name: string; href: string; comment: string option }
type folder = { name: string; bookmarks: bookmark list }
 and bookmark =
    Folder  of folder
  | Item    of item
  | Comment of string

let count_tabs s =
  let rec go n =
    if String.length s = n then -1
    else if s.[n] = '\t' then go (n + 1)
    else n
  in go 0

type line =
  | ItemLine of string      (* lines beginning with '*' *)
  | TextLine of string      (* lines beginning with ';' or ':' *)
  | HeadingLine of string   (* all other lines *)

let fprintf = Printf.fprintf

let print_line fout (l, n) =
  match l with
  | ItemLine s    -> fprintf fout "%2d: Item    (%s)\n" n s
  | TextLine s    -> fprintf fout "%2d: Text    (%s)\n" n s
  | HeadingLine s -> fprintf fout "%2d: Heading (%s)\n" n s

let chop n s = String.trim (String.sub s (n + 1) (String.length s - n - 1))

let parse fin =
  let rec parse_line () =
    try
      let line = input_line fin in
      let n = count_tabs line in
      if n < 0 then parse_line ()
      else
        let lty =
          match line.[n] with
          | '*'       -> ItemLine (chop (n + 1) line)
          | ':' | ';' -> TextLine (chop (n + 1) line)
          | '%'       -> TextLine ""    (* vim comments *)
          | _         -> HeadingLine (String.trim line)
        in (lty, n)
    with End_of_file -> (ItemLine "", -1)
  in

  let rec parse_comment n acc curr =
    match curr with
    | (TextLine s, ln) when ln >= n ->
        let acc' = match acc with
                   | None -> Some s
                   | Some s' -> Some (s' ^ "\n" ^ s)
        in parse_comment n acc' (parse_line ())
    | _ -> (acc, curr)
  in

  let rec parse_at acc n curr =
    (* fprintf stderr "parse_at %d ==> " n; print_line stderr curr; *)
    match curr with
    | (_, ln) when ln < n -> (List.rev acc, curr)
    | (HeadingLine name, _) ->
        let bookmarks, next = parse_at [] (n + 1) (parse_line ()) in
        parse_at (Folder { name; bookmarks }::acc) n next
    | (TextLine s, _) -> parse_at (Comment s::acc) n (parse_line ())
    | (ItemLine name, _) ->
        let href, (comment, next) =
          match parse_line () with
          | (TextLine href, ln) when ln > n ->
              href, parse_comment ln None (parse_line ())
          | next -> "", (None, next)
        in
        let name = if name = "" then href else name in
        let href = if href = "" then name else href in
        parse_at (Item { name; href; comment }::acc) n next
  in
  fst (parse_at [] 0 (parse_line ()))

let encode s = Netencoding.Html.encode ~in_enc:`Enc_utf8 ~out_enc:`Enc_utf8 () s

let only_hyphens s =
  try
    for i = 0 to String.length s - 1 do
      if s.[i] <> ' ' && s.[i] <> '-' then raise Exit
    done;
    true
  with Exit -> false
  

let rec print_bookmark fout bm =
  match bm with
  | Folder {name; bookmarks=[] } when only_hyphens name ->
      fprintf fout "<hr/>"
  | Folder {name; bookmarks } ->
      fprintf fout
        "<li class=\"folder\"><div class=\"folder\"><h3>%s</h3>\n<ul>" name;
      List.iter (print_bookmark fout) bookmarks;
      fprintf fout "</ul></div></li>"
  | Item { name; href; comment } ->
      fprintf fout
        "<li class=\"item\"><div class=\"item\"><a href=\"%s\">%s</a>"
        href (encode name);
      (match comment with None -> () | Some s ->
        fprintf fout "<div class=\"comment\">%s</div>" (encode s));
      fprintf fout "</div></li>\n"
  | Comment s -> fprintf fout "%s" (encode s)

let to_html fin fout =
  fprintf fout "";
  fprintf fout
"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head>
  <title>Bookmarks</title>
  <link rel=\"stylesheet\" href=\"basic.css\" type=\"text/css\" />
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
  <style>
  </style>
  <script type=\"text/javascript\">
#include "CollapsibleLists.js"
  </script></head>
  <body onload=\"CollapsibleLists.apply();\">
   <ul class=\"collapsibleList treeView\">\n";
  List.iter (print_bookmark fout) (parse fin);
  fprintf fout "</ul>";
  fprintf fout "</body></html>\n"
;;

if Array.length Sys.argv = 0
then to_html stdin stdout
else to_html (open_in Sys.argv.(1)) stdout;;

