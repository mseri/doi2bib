(** BibTeX Parser and Pretty Printer

    This module provides comprehensive functionality for parsing, manipulating,
    and formatting BibTeX bibliographic entries. It supports all standard BibTeX
    entry types and provides robust error handling for malformed input. *)

(** Type representing different ways field values can be formatted in BibTeX *)
type field_value =
  | QuotedStringValue of string  (** Value enclosed in double quotes *)
  | BracedStringValue of string  (** Value enclosed in curly braces *)
  | UnquotedStringValue of string  (** Raw unquoted value *)
  | NumberValue of int  (** Numeric value *)

type field = { name : string; value : field_value }
(** A BibTeX field with name and value *)

(** Standard BibTeX entry types *)
type entry_type =
  | Article  (** Journal article *)
  | Book  (** Book with explicit publisher *)
  | Booklet
      (** Work that is printed and bound, but without a named publisher *)
  | Conference  (** Conference proceedings entry *)
  | InBook  (** Part of a book (chapter, section, etc.) *)
  | InCollection  (** Part of a book having its own title *)
  | InProceedings  (** Article in conference proceedings *)
  | Manual  (** Technical documentation *)
  | MastersThesis  (** Master's thesis *)
  | Misc  (** Miscellaneous entry type *)
  | PhdThesis  (** PhD thesis *)
  | Proceedings  (** Conference proceedings *)
  | TechReport  (** Technical report *)
  | Unpublished
      (** Document having an author and title, but not formally published *)

(** Content within a BibTeX entry *)
type entry_content =
  | Field of field  (** A field-value pair *)
  | EntryComment of string  (** Comment within an entry *)

type bibtex_entry = {
  entry_type : entry_type;  (** Type of the entry *)
  citekey : string;  (** Citation key/identifier *)
  contents : entry_content list;  (** List of fields and comments *)
}
(** Complete BibTeX entry *)

(** Top-level BibTeX item *)
type bibtex_item =
  | Entry of bibtex_entry  (** A bibliographic entry *)
  | Comment of string  (** A comment line *)

type parse_error = { line : int; position : int; message : string }
(** Parse error information *)

type parse_result = { items : bibtex_item list; errors : parse_error list }
(** Result of parsing with potential errors *)

(** {2 Parsing Functions} *)

val parse_bibtex : string -> bibtex_item list
(** [parse_bibtex input] parses a BibTeX string into a list of items. This
    function ignores parse errors and returns only successfully parsed items.
    @param input The BibTeX content as a string
    @return List of parsed BibTeX items *)

val parse_bibtex_with_errors : string -> parse_result
(** [parse_bibtex_with_errors input] parses a BibTeX string and returns both
    successfully parsed items and any errors encountered.
    @param input The BibTeX content as a string
    @return Parse result containing items and errors *)

val has_parse_errors : parse_result -> bool
(** [has_parse_errors result] checks if a parse result contains any errors.
    @param result The parse result to check
    @return true if there are errors, false otherwise *)

val get_parse_errors : parse_result -> parse_error list
(** [get_parse_errors result] extracts the list of parse errors.
    @param result The parse result
    @return List of parse errors *)

val get_parsed_items : parse_result -> bibtex_item list
(** [get_parsed_items result] extracts the list of successfully parsed items.
    @param result The parse result
    @return List of parsed BibTeX items *)

(** {2 Pretty Printers} *)

val pretty_print_bibtex : bibtex_item list -> string
(** [pretty_print_bibtex items] formats a list of BibTeX items into a complete
    BibTeX string.
    @param items List of BibTeX items to format
    @return Complete formatted BibTeX string *)

val clean_bibtex : string -> string
(** [clean_bibtex input] parses and reformats BibTeX input, effectively cleaning
    and normalizing the formatting.
    @param input The BibTeX content to clean
    @return Cleaned and reformatted BibTeX string *)

(** {2 Utility Functions for custom formatting or editing} *)

val string_of_entry_type : entry_type -> string
(** [string_of_entry_type entry_type] converts an entry type to its string
    representation (e.g., Article becomes "article"). *)

val entry_type_of_string : string -> entry_type
(** [entry_type_of_string str] converts a string to an entry type.
    @param str The string representation (case-insensitive)
    @return The corresponding entry type
    @raise Invalid_argument if the string is not a recognized entry type *)

val format_field_value : field_value -> string
(** [format_field_value value] formats a field value for output.
    @param value The field value to format
    @return String representation of the value *)

val format_field_value_with_url_unescaping : string -> field_value -> string
(** [format_field_value_with_url_unescaping field_name value] formats a field
    value with URL unescaping and Unicode normalization applied. Special
    handling is applied to URL fields.
    @param field_name
      The name of the field (used to determine if URL processing is needed)
    @param value The field value to format
    @return String representation with URLs unescaped if applicable *)

val format_field : field -> string
(** [format_field field] formats a complete field (name = value).
    @param field The field to format
    @return String representation of the field *)

val format_entry_content : entry_content -> string
(** [format_entry_content content] formats entry content (field or comment).
    @param content The entry content to format
    @return String representation of the content *)

val format_entry : bibtex_entry -> string
(** [format_entry entry] formats a complete BibTeX entry.
    @param entry The entry to format
    @return String representation of the entry *)

val format_bibtex_item : bibtex_item -> string
(** [format_bibtex_item item] formats a BibTeX item (entry or comment).
    @param item The item to format
    @return String representation of the item *)
