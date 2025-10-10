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

type options = { capitalize_names : bool; strict : bool; align_entries : bool }
(** Options for parsing and formatting BibTeX entries:
    - [capitalize_names]: If true, the field names are made upper capital.
    - [strict]: If true, parsing will be stricter and reject bibtex files with
      duplicate fields.
    - [align_entries]: If true, entries name and equal signs will be aligned for
      better readability. *)

val default_options : options
(** Default formatting options for BibTeX entries: [capitalize_names: true],
    [strict: false], [align_entries: true] *)

val pretty_print_bibtex : ?options:options -> bibtex_item list -> string
(** [pretty_print_bibtex items] formats a list of BibTeX items into a complete
    BibTeX string.
    @param options Formatting options
    @param items List of BibTeX items to format
    @return Complete formatted BibTeX string *)

val clean_bibtex : ?options:options -> string -> string
(** [clean_bibtex input] parses and reformats BibTeX input, effectively cleaning
    and normalizing the formatting.
    @param options Formatting options (defaults to the value of default_options)
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

val format_field : bool -> field -> string
(** [format_field field] formats a complete field (name = value).
    @param field The field to format
    @return String representation of the field *)

val format_entry_content : bool -> entry_content -> string
(** [format_entry_content content] formats entry content (field or comment).
    @param content The entry content to format
    @return String representation of the content *)

val format_entry : options -> bibtex_entry -> string
(** [format_entry entry] formats a complete BibTeX entry.
    @param entry The entry to format
    @return String representation of the entry *)

val format_bibtex_item : options -> bibtex_item -> string
(** [format_bibtex_item item] formats a BibTeX item (entry or comment).
    @param item The item to format
    @return String representation of the item *)

(** {2 Deduplication Functions} *)

type field_conflict = {
  field_name : string;
  values : (string * int) list;  (** (value, entry_index) pairs *)
}
(** Type representing a field conflict between duplicate entries. Each value is
    paired with the index of the entry it came from. *)

type duplicate_group = {
  entries : bibtex_entry list;  (** The group of duplicate entries *)
  matching_keys : (string * string) list;  (** Key-value pairs that match *)
  conflicts : field_conflict list;  (** Fields that differ between entries *)
}
(** Type representing a group of duplicate entries identified by matching key
    fields *)

val find_duplicate_groups :
  ?keys:string list -> bibtex_entry list -> duplicate_group list
(** [find_duplicate_groups ~keys entries] identifies groups of duplicate entries
    without resolving them.

    @param keys
      List of field names to use for duplicate detection (default:
      [["title"; "author"; "year"]]). Use ["citekey"] to match on citation keys.
    @param entries List of BibTeX entries to analyze
    @return List of duplicate groups found

    This is useful for inspecting duplicates before deciding how to handle them.
    Each group contains at least 2 entries that match on the specified keys. *)

val merge_entries_non_interactive : bibtex_entry list -> bibtex_entry
(** [merge_entries_non_interactive entries] merges duplicate entries by keeping
    the first occurrence of each field.

    @param entries List of duplicate entries to merge (must be non-empty)
    @return Merged entry with fields from the first entry taking precedence
    @raise Invalid_argument if the entries list is empty

    This function does not prompt the user and simply takes the first value it
    encounters for each field. It's useful for batch processing or when you
    trust the ordering of your entries. *)

val string_of_field_value : field_value -> string
(** [string_of_field_value fv] converts a field value to its string representation.
    @param fv The field value to convert
    @return String representation of the field value *)

val make_field : string -> string -> entry_content
(** [make_field name value] creates a BibTeX field with the given name and value.
    The value is wrapped in braces.
    @param name Field name
    @param value Field value as a string
    @return An entry_content Field with a BracedStringValue *)
