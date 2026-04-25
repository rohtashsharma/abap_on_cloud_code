CLASS zcl_tech_rs_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    DATA: lv_ops TYPE c VALUE 'R'.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_tech_rs_eml IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    CASE lv_ops.
      WHEN 'R'.
        "EML to Read Data
        READ ENTITIES OF ztech_rs_travel
            ENTITY Travel
            FIELDS ( travelid agencyid customerid begindate totalprice currencycode ) WITH
            VALUE #(
                       ( travelid = '00000010' )   "Present in db
                       ( travelid = '00000024' )   "Present
                       ( travelid = '989999' )     "Not present
                    )
            RESULT DATA(lt_result)
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported) .

        "Read dependent booking data for Travel
        READ ENTITIES OF ztech_rs_travel
           ENTITY Travel
           BY \_Booking ALL FIELDS WITH
           CORRESPONDING #( lt_result )
           RESULT DATA(lt_result_book)
           FAILED lt_failed
           REPORTED lt_reported.

*        out->write(
*          EXPORTING
*            data   = lt_result
*        ).

        out->write(
          EXPORTING
            data   = lt_result_book
        ).

        out->write(
          EXPORTING
            data   = lt_failed
        ).

        out->write(
          EXPORTING
            data   = lt_reported
        ).


      WHEN 'C'.
        "Prapare test data for create
        DATA(lv_descr) = 'ROH with ABAP'.
        DATA(lv_agency) = '070016'.
        DATA(lv_cust) = '000697'.

        MODIFY ENTITIES OF ztech_rs_travel
            ENTITY Travel
            CREATE FIELDS ( travelid agencyid customerid begindate enddate totalprice currencycode bookingfee description overallstatus )
            WITH VALUE #(
                           (
                              %cid = 'CID1'
                              travelid = '00118899'
                              agencyid = lv_agency
                              CustomerId = lv_cust
                              BeginDate = cl_abap_context_info=>get_system_date(  )
                              enddate = cl_abap_context_info=>get_system_date(  ) + 30
                              Description = lv_descr
                              OverallStatus = 'O'
                           )
                           (
                              %cid = 'CID2'
                              travelid = '00118898'
                              agencyid = lv_agency
                              CustomerId = lv_cust
                              BeginDate = cl_abap_context_info=>get_system_date(  )
                              enddate = cl_abap_context_info=>get_system_date(  ) + 30
                              Description = lv_descr
                              OverallStatus = 'O'
                           )
                           (
                              %cid = 'CID3'
                              travelid = '00118899'   "id is same as 1st
                              agencyid = lv_agency
                              CustomerId = lv_cust
                              BeginDate = cl_abap_context_info=>get_system_date(  )
                              enddate = cl_abap_context_info=>get_system_date(  ) + 30
                              Description = lv_descr
                              OverallStatus = 'O'
                           )
                        )
            FAILED lt_failed
            REPORTED lt_reported
            MAPPED DATA(lt_mapped).

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
        ).

        out->write(
          EXPORTING
            data   = lt_failed
        ).


      WHEN 'U'.
        "Prepare test data for update
        lv_descr = 'ROH changed!'.
        lv_agency = '070022'.

        MODIFY ENTITIES OF ztech_rs_travel
            ENTITY Travel
            UPDATE FIELDS ( agencyid description )
            WITH VALUE #(
                           (
                              travelid = '00118899'
                              agencyid = lv_agency
                              Description = lv_descr
                           )
                           (
                              travelid = '00118898'
                              agencyid = lv_agency
                              Description = lv_descr
                           )
                        )
          FAILED lt_failed
          REPORTED lt_reported
          MAPPED lt_mapped.

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
        ).

        out->write(
          EXPORTING
            data   = lt_failed
        ).


      WHEN 'D'.

        MODIFY ENTITIES OF ztech_rs_travel
            ENTITY Travel
            DELETE FROM
                VALUE #(
                           (
                              travelid = '00118899'
                           )
                           (
                              travelid = '00118898'
                           )
                        )
          FAILED lt_failed
          REPORTED lt_reported
          MAPPED lt_mapped.

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
        ).

        out->write(
          EXPORTING
            data   = lt_failed
        ).

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
