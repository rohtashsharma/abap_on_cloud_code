*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsuppl.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    DATA max_book_suppl_id TYPE /dmo/booking_id.

    "entities have %cid_ref, travelid, bookingid and %target:standard table of booking suppliment
    "with travelid, bookingid, bookingsupplementid and other fields of suppliment data

    "Step 1: Get all the travel requests and their booking suppliments
    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
        ENTITY booking BY \_BookingSuppl
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_booking_suppl).

    "lt_booking_supp has 2 field, Source: travelid, bookingid and target: travelid, bookingid, bookingsupplimentid
    SORT lt_booking_suppl BY source-TravelId source-BookingId target-BookingSupplementId DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_booking_suppl COMPARING source-TravelId source-BookingId.

    "Group entities by suppliment id
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky-BookingId.

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity
                                                       WHERE travelid = <booking_group>-travelid
                                                         AND bookingid = <booking_group>-bookingid.
        "Get max suppliment id
        max_book_suppl_id = VALUE #( lt_booking_suppl[ source-travelid = <booking_group>-travelid
                                                       source-bookingid = <booking_group>-bookingid ]-target-BookingSupplementId OPTIONAL ).

        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_number>).
          APPEND CORRESPONDING #( <booksuppl_wo_number> ) TO mapped-booksupppl
                    ASSIGNING FIELD-SYMBOL(<mapped_book_suppl>).

          IF <mapped_book_suppl>-BookingSupplementId IS INITIAL.
            max_book_suppl_id += 1.
            <mapped_book_suppl>-BookingSupplementId = max_book_suppl_id.
          ENDIF.

        ENDLOOP.

        CLEAR max_book_suppl_id.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
