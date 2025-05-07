# News and Notifications by Version

This file lists noteworthy changes which may affect users of this project.  More
detailed information is available in the rest of the documentation.

**NOTE:** Date stamps in the following entries are in YYYY/MM/DD format.


## v0.4.0.pre1 (2025/05/07)
* Reimplemented all version specific IO::Like modules as a single class
  * **WARNING:** Breaks API compatibility with prior versions
* Dropped support for Ruby less than 2.7
* Added full API compatibility for Ruby 2.7 through 3.4
  * Support for character encodings
  * Asynchronous/nonblocking methods
  * Many missing helper methods
* Reworked spec handling to make it easier to import rubyspec snapshots almost
  trivially (Grant Gardner, Jeremy Bopp)
* Added code coverage tooling


## v0.3.1 (2020/02/09)

* Removed the rubyforge reference from the gemspec (Jordan Pickwell)


## v0.3.0 (2009/04/29)

* Fixed the rewind method to work with write-only streams
* Fixed the read, gets, and readline methods to return partial data if they have
  such data but receive low level errors before reaching a stopping point
* Renamed all private methods so that it is highly unlikely that they will be
  accidentally overridden
* Eliminated warnings caused by referencing uninitialized instance variables
* Improved the documentation for the read, gets, and readline methods


## v0.2.0 (2009/03/11)

* Added mspec tests borrowed from the rubyspec project
* Fixed many, many defects related to IO compatibility (Mostly obscure corner
  cases)


## v0.1.0 (2008/07/03)

* Initial release
* All read, write, and seek functions implemented as defined in Ruby 1.8.6
* Most other IO methods also provided as no-ops and similar
