CLASS zcl_tech_rs_ve DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_tech_rs_ve IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.

    CHECK NOT it_original_data IS INITIAL.

    DATA : lt_calc_data TYPE STANDARD TABLE OF ztech_rs_travel_processor WITH DEFAULT KEY,
           lv_rate      TYPE p DECIMALS 2 VALUE '0.025'.

    lt_calc_data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_calc_data ASSIGNING FIELD-SYMBOL(<fs_calc_data>).

      <fs_calc_data>-CO2Tax = <fs_calc_data>-TotalPrice * lv_rate.
      ""here you can write code to get day of travel
      <fs_calc_data>-dayOfFlight = 'Sunday'.

    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_calc_data ).

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.
ENDCLASS.


