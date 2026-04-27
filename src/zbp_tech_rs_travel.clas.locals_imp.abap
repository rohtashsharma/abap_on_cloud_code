CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

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

ENDCLASS.
