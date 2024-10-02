# Clean PsycInfo export --------------------------------------------------------
#
# In the export dialogue, select `Citavi` for Format and `Complete Reference`
# for Fields.
# Store the exported files in the folder `data-raw`.
#
# Process `.ovd` files exported by ovid / PsycInfo
# * Use ISO 639 codes
# * Remove data base / archive field
require(magrittr)
require(tidyverse)
require(ISOcodes)

files <-
  dir(
    "data-raw",
    pattern = ".ovd$",
    full.names = TRUE
  )

fields_to_clean <-
  c(
    "DB  - ",
    "VN  - Ovid Technologies",
    "AN  -",
    "PH  - ",
    "AI  - ",
    "MA  - ",
    "CQ  - ",
    "IN  -",
    "PE  -",
    "IT  -",
    "PU  -",
    "FO  -",
    "CC  -",
    "PO  -",
    "LO  -",
    "MD  -",
    "GS  -",
    "RF  -",
    "UP  -",
    "PG  - No Pagination Specified",
    "PS  - First Posting",
    "XL  - https://ovidsp.ovid.com/"
  )

iso_languages <-
  ISO_639_2 %>%
  filter(!is.na(Alpha_2)) %>%
  select(Name, Alpha_2)
language_to_iso <-
  iso_languages$Alpha_2 %>%
  setNames(iso_languages$Name)

references <-
  map(
    files,
    function(f) {
      reference <-
        read_lines(file = f)
      reference <-
        reference[
          !grepl(
            pattern =
              str_flatten(
                string = fields_to_clean,
                collapse = "|"
              ),
            x = reference
          )
        ]
      language_lines <-
        which(
          str_detect(
            string = reference,
            pattern = "^LG  - "
          )
        )
      reference[language_lines] <-
        reference[language_lines] %>%
        str_replace_all(
          pattern = language_to_iso
        )
      reference
    }
  )

references %<>%
  reduce(c)

id_lines <-
  which(
    str_detect(
      string = references,
      pattern = "^<[0-9]"
    )
  )

references[id_lines] <-
  str_c(
    "<",
    seq_along(id_lines),
    ". >"
  )

writeLines(
  text = references,
  con = "data/PsycInfo-results.ovd",
  sep = "\n"
)
