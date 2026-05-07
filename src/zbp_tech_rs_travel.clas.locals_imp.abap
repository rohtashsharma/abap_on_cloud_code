CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.
    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.
    METHODS calctotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calctotalprice.

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

  METHOD earlynumbering_create. "Early Numbering
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

  METHOD earlynumbering_cba_Booking.  "Early Numbering

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

  METHOD get_instance_features.  "Feature Control
    "Use Case: Check the status of the current travel request
    "          if cancelled, disable the booking creation

    "Step 1: EML to read the travel status
    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
      ENTITY travel
        FIELDS ( travelid overallstatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result)
      FAILED DATA(lt_failed).

    "Step 2: return the result with booking creation is possible or not
    READ TABLE lt_result INTO DATA(ls_result) INDEX 1.

    IF ( ls_result-OverallStatus = 'X' ).
      DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
    ELSE.
      lv_allow = if_abap_behv=>fc-o-enabled.
    ENDIF.

    result = VALUE #( FOR wa_result IN lt_result ( %tky = wa_result-%tky
                                                   %assoc-_Booking = lv_allow ) ).

  ENDMETHOD.

  METHOD copyTravel.  "Data Action

    "Shallow Copy: Header
    "Deep Copy: Header, Items, Sub Items

    "Step 1: Declare data to store new records
    DATA: travels       TYPE TABLE FOR CREATE ztech_rs_travel\\Travel,
          bookings_cba  TYPE TABLE FOR CREATE ztech_rs_travel\\Travel\_Booking,
          booksuppl_cba TYPE TABLE FOR CREATE ztech_rs_travel\\Booking\_BookingSuppl.

    "Step 2: Validate to make sure no data with blank %cid is allowed
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_initial_cid).
    ASSERT key_with_initial_cid IS INITIAL.

    "Step 3: Read all existing data of Travel, Booking & Suppliment
    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY Travel
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(travel_read_result)
        FAILED failed.

    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking
        ALL FIELDS WITH CORRESPONDING #( travel_read_result )
        RESULT DATA(book_read_result)
        FAILED failed.

    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY booking BY \_BookingSuppl
        ALL FIELDS WITH CORRESPONDING #( book_read_result )
        RESULT DATA(booksuppl_read_result)
        FAILED failed.

    "Step 4: Prepare the data to be inserted in DB
    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).

      "For Travel we just need to pass incoming cid, but for booking and booksupp we need to prepare cid and pass
      "Trvael data prepare
      APPEND VALUE #( %cid = keys[ %tky = <travel>-%tky ]-%cid
                      %data = CORRESPONDING #( <travel> EXCEPT travelid )
                    ) TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date(  ).
      <new_travel>-ENDDate = cl_abap_context_info=>get_system_date(  ) + 30.
      <new_travel>-OverallStatus = 'N'.

      "Booking data preparation
      "We have to pass %cid_ref to tell system, that the bookings belong to
      "which travel request - a record was inserted in itab for booking
      APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid
                    ) TO bookings_cba ASSIGNING FIELD-SYMBOL(<booking_cba>).

      "Prepare all the bookings from existing request which needs to be copied
      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) WHERE travelid = <travel>-TravelId.

        "Lets pass a unique booking cid - concatenate the CID of travel with booking id of existing travel
        APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                        %data = CORRESPONDING #( book_read_result[ KEY entity %tky = <booking>-%tky ] EXCEPT travelid ) )
                    TO <booking_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.

        ""-Start of Supplement
        "Booking data preparation
        APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                    ) TO booksuppl_cba ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

        "Prepare all the bookings from existing request which needs to be copied
        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<book_suppl>) USING KEY entity WHERE travelid = <travel>-TravelId
                                                                                              AND bookingid = <booking>-bookingid.

          "Lets pass a unique booking cid - concatenate the CID of travel with booking id of existing travel
          APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId && <book_suppl>-BookingSupplementId
                          %data = CORRESPONDING #( <book_suppl> EXCEPT travelid bookingid ) )
                      TO <booksuppl_cba>-%target.

        ENDLOOP.
        ""-End of Supplement


      ENDLOOP.

    ENDLOOP.

    "Step 5: Insert data in DB using EML
    MODIFY ENTITIES OF ztech_rs_travel IN LOCAL MODE
        ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus )
         WITH travels
          CREATE BY \_Booking FIELDS ( bookingid bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
            WITH bookings_cba
                ENTITY booking
                    CREATE BY \_BookingSuppl FIELDS ( BookingSupplementId SupplementId price currencycode )
                       WITH booksuppl_cba
        MAPPED DATA(mapped_data).

*    mapped-travel = mapped_data-travel.  "In case of shallow copy only
    mapped = mapped_data.

  ENDMETHOD.

  METHOD reCalcTotalPrice.  "Internal Action

    "Define a structure where we can store all the Booking Fees and Currency Code
    TYPES: BEGIN OF ty_total_cost,
             amount   TYPE /dmo/total_price,
             currency TYPE /dmo/currency_code,
           END OF ty_total_cost.

    DATA ls_header_curr TYPE /dmo/currency_code.
    DATA amounts_per_currencycode TYPE STANDARD TABLE OF ty_total_cost.

    "Read all the travel instances, subsequent Bookings inside that using EML
    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY Travel
        FIELDS ( bookingfee currencycode ) WITH CORRESPONDING #( keys )
        RESULT DATA(travel)
        FAILED failed.

    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY Travel BY \_Booking
        FIELDS ( flightprice currencycode ) WITH CORRESPONDING #( travel )
        RESULT DATA(booking)
        FAILED failed.

    READ ENTITIES OF ztech_rs_travel IN LOCAL MODE
    ENTITY booking BY \_BookingSuppl
        FIELDS ( price currencycode ) WITH CORRESPONDING #( booking )
        RESULT DATA(booksuppl)
        FAILED failed.

    "Delete records where currencycode is empty, optionally throw error
    DELETE travel WHERE currencycode IS INITIAL.
    DELETE booking WHERE currencycode IS INITIAL.
    DELETE booksuppl WHERE currencycode IS INITIAL.

    "Loop at header, item and item childs, total all the amounts in itab for common currency
    LOOP AT travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      amounts_per_currencycode = VALUE #( ( amount = <fs_travel>-BookingFee
                                            currency = <fs_travel>-CurrencyCode ) ).

      ls_header_curr = <fs_travel>-CurrencyCode.

      LOOP AT booking INTO DATA(ls_booking) WHERE travelid = <fs_travel>-TravelId.

        "Collect all numeric column values by comparing non-numeric columns
        COLLECT VALUE ty_total_cost( amount = ls_booking-FlightPrice
                                     currency = ls_booking-CurrencyCode )
                             INTO amounts_per_currencycode.

        LOOP AT booksuppl INTO DATA(ls_booksuppl) WHERE travelid = ls_booking-TravelId
                                                    AND bookingid = ls_booking-bookingid.

          COLLECT VALUE ty_total_cost( amount = ls_booksuppl-Price
                                       currency = ls_booksuppl-CurrencyCode )
                           INTO amounts_per_currencycode.

        ENDLOOP.
      ENDLOOP.
      CLEAR <fs_travel>-totalprice.
    ENDLOOP.

    "Compare the currency of Booking and Supplement with header currency
    LOOP AT amounts_per_currencycode INTO DATA(ls_amount_per_currencycode).
      "If it does not match, perform currency conversion
      IF ls_amount_per_currencycode-currency = ls_header_curr.
        <fs_travel>-TotalPrice += ls_amount_per_currencycode-amount.

      ELSE.

        /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
            iv_amount               = ls_amount_per_currencycode-amount
            iv_currency_code_source = ls_amount_per_currencycode-currency
            iv_currency_code_target = ls_header_curr
            iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
          IMPORTING
            ev_amount               = DATA(total_amt)
        ).

        <fs_travel>-TotalPrice += total_amt.

      ENDIF.
    ENDLOOP.

    "Total all the amount in a variable and set it to the Travel header level using EML
    MODIFY ENTITIES OF ztech_rs_travel IN LOCAL MODE
        ENTITY travel
            UPDATE FIELDS ( totalprice )
                WITH CORRESPONDING #( travel ).
    "Return the mapped data as a result of internal action


  ENDMETHOD.

  METHOD calcTotalPrice. "Determination

    "How to call an action using EML
    MODIFY ENTITIES OF ztech_rs_travel IN LOCAL MODE
        ENTITY travel
            EXECUTE reCalcTotalPrice
            FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
