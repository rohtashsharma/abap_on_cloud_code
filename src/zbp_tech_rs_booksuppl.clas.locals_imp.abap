CLASS lhc_BookSupppl DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calcTotalPriceSuppl FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookSupppl~calcTotalPriceSuppl.

ENDCLASS.

CLASS lhc_BookSupppl IMPLEMENTATION.

  METHOD calcTotalPriceSuppl.

    "How to call an action using EML
    MODIFY ENTITIES OF ztech_rs_travel IN LOCAL MODE
        ENTITY travel
            EXECUTE reCalcTotalPrice
            FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
