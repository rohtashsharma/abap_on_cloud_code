CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
    "AUTHORITY_CHECK
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA: entity        TYPE STRUCTURE FOR CREATE ztech_rs_travel,
          travel_id_max TYPE /dmo/travel_id.

    "Step 1: Ensure that the travel id is not passed by user, so we can generate id
    LOOP AT entities INTO entity WHERE travelid IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    "Step 2: lets take all travel request data in another copy
    "        filter out record which has travel id, only keep where travel id is blank
    DATA(entities_wo_travelid) = entities.
    DELETE entities_wo_travelid WHERE travelid IS NOT INITIAL.

    "Step 3: Use SNRO generator to create travel id
    " Example: current no 422, i want 3 = 426, 426-3 = 423
    " 423+1 = 424, 424+1 = 425, 425+1 = 426
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
*             ignore_buffer     =
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_range_return_code)
            returned_quantity = DATA(number_range_returned_quantity)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        "Step 4: If there is a dump inside, we will just fill failed and reported
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %msg = lx_number_ranges )
              TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key )
              TO failed-travel.
        ENDLOOP.
    ENDTRY.

    "Step 5: Handle special cases if no. range exhaused, about to get exhaused
    CASE number_range_return_code.
      WHEN '1'.
        "About to exhause 99% numbers finished
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid  %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                         textid = /dmo/cm_flight_messages=>number_range_depleted
                                         severity = if_abap_behv_message=>severity-warning )
                        )
                        TO reported-travel.
        ENDLOOP.

      WHEN '2' OR '3'.
        "Last number was returned or no. range exhaused
        APPEND VALUE #( %cid = entity-%cid  %key = entity-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                       textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                       severity = if_abap_behv_message=>severity-warning )
                       )
                       TO reported-travel.
        APPEND VALUE #( %cid = entity-%cid  %key = entity-%key
                        %fail-cause = if_abap_behv=>cause-conflict
                      )
                      TO failed-travel.

    ENDCASE.

    "Step 6: Final check for all numbers
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).

    "Step 7: Loop over the incoming data and assign the travel id by incrementing it
    "        send the data wrapped to RAP framework
    travel_id_max = number_range_key - number_range_returned_quantity.

    LOOP AT entities_wo_travelid INTO entity.
      travel_id_max += 1.
      entity-TravelId = travel_id_max.

      APPEND VALUE #( %cid = entity-%cid %key = entity-%key ) TO mapped-travel.

    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA max_booking_id TYPE /dmo/booking_id.
    "entities parameter have 2 fields
    "1. travel id, 2. %target: standard table of booking data
    "1 travel id has 1 target:standard table with multiple booking ids

    "Step 1: Get all the travel requests and their bookings
    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
       ENTITY travel BY \_Booking
       FROM CORRESPONDING #( entities )
       LINK DATA(lt_bookings).
    "Here lt_bookings will have 2 fields
    " 1. Source: having travel id, 2. Target: structure having travel id & booking id
    "if 1 travel id has 3 booking ids then there will be 3 records in lt_booking for that travel id

    """"Option 1 to get Max booking id
*    "Step 2: Cases to handle for Assigning unique booking id
*    "1001, 1002, 1005
*    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-TravelId.
*
*      "Step 3: Loop at the specific booking of every unique travel id
*      "Pass 1 - 10,20
*      "Pass 2 - 10
*      "Pass 3 - 40,50
*      LOOP AT lt_bookings INTO DATA(ls_bookings) USING KEY entity
*                              WHERE source-Travelid = <travel_group>-TravelId.
*        "Determine the already created booking id which is maximum
*        IF max_booking_id < ls_bookings-target-Bookingid.
*          max_booking_id = ls_bookings-target-BookingId.
*        ENDIF.
*      ENDLOOP.
*
*    ENDLOOP.
    """" End of option 1

    """" option 2 of getting max booking id
    SORT lt_bookings BY source-TravelId ASCENDING target-BookingId DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_bookings COMPARING source-TravelId.
    """" End of option 2

    "Step 4: loop over all the entities of travel with same travel id and increment the max booking id
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>) GROUP BY <travel>-TravelId.
      """" option 2 of getting max booking id
*    READ TABLE lt_bookings INTO DATA(wa_bookings) WITH KEY source-TravelId = <travel>-TravelId.
*    if sy-subrc eq 0.
*    endif.

      "Step 5: Increment the booking id +10 and assign the new id
      max_booking_id = VALUE #( lt_bookings[ source-TravelId = <travel>-TravelId ]-target-BookingId OPTIONAL ).
      """" End of option 2

*      "Step 5: Increment the booking id +10 and assign the new id
      LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<travel_wo_number>).
        APPEND CORRESPONDING #( <travel_wo_number> ) TO mapped-booking
                             ASSIGNING FIELD-SYMBOL(<mapped_booking>).
        "Determine the already created booking id which is maximum
        "Assigning the +10 as new booking id
        IF <mapped_booking>-Bookingid IS INITIAL.
          max_booking_id += 10.
          <mapped_booking>-bookingid = max_booking_id.
        ENDIF.
      ENDLOOP.

      CLEAR: max_booking_id.   "part of Option 2

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
