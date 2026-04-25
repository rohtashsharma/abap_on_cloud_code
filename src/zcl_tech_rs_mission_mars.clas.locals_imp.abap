*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
* Class pools
CLASS lcl_earth_rs DEFINITION.   "Class 1 Defination
  PUBLIC SECTION.
    CLASS-METHODS start_engine RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS leave_orbit RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_earth_rs IMPLEMENTATION.  "Class 1 Implementation

  METHOD leave_orbit.
    r_result = 'We are out of space'.
  ENDMETHOD.

  METHOD start_engine.
    r_result = 'We start the countdown!'.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_ip_rs DEFINITION.    "Class 2 Defination
  PUBLIC SECTION.
    CLASS-METHODS enter_orbit RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS leave_orbit RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_ip_rs IMPLEMENTATION.   "Class 2 Implementation

  METHOD leave_orbit.
    r_result = 'Leave orbit and continue mission'.
  ENDMETHOD.

  METHOD enter_orbit.
    r_result = 'We enter orbit, start charging'.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_mars_rs DEFINITION.   "Class 3 Defination
  PUBLIC SECTION.
    CLASS-METHODS enter_orbit RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS start_exploration RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_mars_rs IMPLEMENTATION.   "Class 3 Implementation

  METHOD enter_orbit.
    r_result = 'We enter mars.'.
  ENDMETHOD.

  METHOD start_exploration.
    r_result = 'We found water on mars'.
  ENDMETHOD.

ENDCLASS.
