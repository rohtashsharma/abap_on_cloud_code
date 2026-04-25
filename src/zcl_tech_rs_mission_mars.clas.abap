CLASS zcl_tech_rs_mission_mars DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: itab TYPE TABLE OF string.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_tech_rs_mission_mars IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA(lv_str) = lcl_earth_rs=>start_engine(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_earth_rs=>leave_orbit(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_ip_rs=>enter_orbit(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_ip_rs=>leave_orbit(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_mars_rs=>enter_orbit(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_mars_rs=>start_exploration(  ).
    APPEND lv_str TO itab.

    out->write(
      EXPORTING
        data   = itab
*        name   =
*      RECEIVING
*        output =
    ).

  ENDMETHOD.
ENDCLASS.
