CLASS lsc_zrtr_i_travel_m DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zrtr_i_travel_m IMPLEMENTATION.

  METHOD save_modified.

    DATA travel_log        TYPE STANDARD TABLE OF zrtr_log_travel.
    DATA travel_log_create TYPE STANDARD TABLE OF zrtr_log_travel.
    DATA travel_log_update TYPE STANDARD TABLE OF zrtr_log_travel.

    " (1) Get instance data of all instances that have been created
    IF create-travel IS NOT INITIAL.
      " Creates internal table with instance data
      travel_log = CORRESPONDING #( create-travel MAPPING travel_id = TravelId ).
      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<travel_log>).
        <travel_log>-changing_operation = 'CREATE'.
        " Generate time stamp
        GET TIME STAMP FIELD <travel_log>-created_at.
        " Read travel instance data into ls_travel that includes %control structure
        READ TABLE create-travel WITH TABLE KEY entity COMPONENTS travelid = <travel_log>-travel_id INTO DATA(travel).
        IF sy-subrc = 0.
          " If new value of the booking_fee field created
          IF travel-%control-bookingfee = cl_abap_behv=>flag_changed.
            " Generate uuid as value of the change_id field
            TRY.
                <travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.
            <travel_log>-changed_field_name = 'booking_fee'.
            <travel_log>-changed_value = travel-bookingfee.
            APPEND <travel_log> TO travel_log_create.
          ENDIF.

          " If new value of the overall_status field created
          IF travel-%control-overallstatus = cl_abap_behv=>flag_changed.
            " Generate uuid as value of the change_id field
            TRY.
                <travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
              CATCH cx_uuid_error.
                "handle exception
            ENDTRY.
            <travel_log>-changed_field_name = 'overall_status'.
            <travel_log>-changed_value = travel-overallstatus.
            APPEND <travel_log> TO travel_log_create.
          ENDIF.

          " IF  ls_travel-%control-...

        ENDIF.

      ENDLOOP.

      " Inserts rows specified in lt_travel_log_c into the DB table /dmo/log_travel
      INSERT zrtr_log_travel FROM TABLE @travel_log_create.

    ENDIF.


    " (2) Get instance data of all instances that have been updated during the transaction
    IF update-travel IS NOT INITIAL.
      travel_log = CORRESPONDING #( update-travel MAPPING travel_id = TravelId ).

      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<travel_log_update>).

        ASSIGN travel_log[ travel_id = <travel_log_update>-travelid ] TO FIELD-SYMBOL(<travel_log_db>).

        <travel_log_db>-changing_operation = 'UPDATE'.

        " Generate time stamp
        GET TIME STAMP FIELD <travel_log_db>-created_at.


        IF <travel_log_update>-%control-customerid = if_abap_behv=>mk-on.
          <travel_log_db>-changed_value = <travel_log_update>-customerid.
          " Generate uuid as value of the change_id field
          TRY.
              <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.

          <travel_log_db>-changed_field_name = 'customer_id'.

          APPEND <travel_log_db> TO travel_log_update.

        ENDIF.

        IF <travel_log_update>-%control-description = if_abap_behv=>mk-on.
          <travel_log_db>-changed_value = <travel_log_update>-description.

          " Generate uuid as value of the change_id field
          TRY.
              <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
            CATCH cx_uuid_error.
              "handle exception
          ENDTRY.

          <travel_log_db>-changed_field_name = 'description'.

          APPEND <travel_log_db> TO travel_log_update.

        ENDIF.

        "IF <fs_travel_log_u>-%control-...

      ENDLOOP.


      " Inserts rows specified in lt_travel_log_u into the DB table /dmo/log_travel
      INSERT zrtr_log_travel FROM TABLE @travel_log_update.

    ENDIF.

    " (3) Get keys of all travel instances that have been deleted during the transaction
    IF delete-travel IS NOT INITIAL.
      travel_log = CORRESPONDING #( delete-travel mapping travel_id = TravelId ).
      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<travel_log_delete>).
        <travel_log_delete>-changing_operation = 'DELETE'.
        " Generate time stamp
        GET TIME STAMP FIELD <travel_log_delete>-created_at.
        " Generate uuid as value of the change_id field
        TRY.
            <travel_log_delete>-change_id = cl_system_uuid=>create_uuid_x16_static( ) .
          CATCH cx_uuid_error.
            "handle exception
        ENDTRY.

      ENDLOOP.

      " Inserts rows specified in lt_travel_log into the DB table /dmo/log_travel
      INSERT zrtr_log_travel FROM TABLE @travel_log.

    ENDIF.



  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS acceptTravel FOR MODIFY
       keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS copyTravel FOR MODIFY
       keys FOR ACTION Travel~copyTravel.

    METHODS reCalTotalPrice FOR MODIFY
       keys FOR ACTION Travel~reCalTotalPrice.

    METHODS rejectTravel FOR MODIFY
       keys FOR ACTION Travel~rejectTravel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Travel RESULT result.
    METHODS validateagency FOR VALIDATE ON SAVE
       keys FOR travel~validateagency.

    METHODS validatebookingfee FOR VALIDATE ON SAVE
       keys FOR travel~validatebookingfee.

    METHODS validatecurrencycode FOR VALIDATE ON SAVE
       keys FOR travel~validatecurrencycode.

    METHODS validatecustomer FOR VALIDATE ON SAVE
       keys FOR travel~validatecustomer.

    METHODS validatedates FOR VALIDATE ON SAVE
       keys FOR travel~validatedates.

    METHODS validatestatus FOR VALIDATE ON SAVE
       keys FOR travel~validatestatus.
    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
       keys FOR travel~calculatetotalprice.
    METHODS earlynumbering_cba_Booking FOR NUMBERING
       entities FOR CREATE Travel\_Booking.
    METHODS earlynumbering_create FOR NUMBERING
       entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA: entity TYPE STRUCTURE FOR CREATE zrtr_i_travel_m.
** Delete Entities which has travel id initial
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entities>) WHERE TravelId IS NOT INITIAL.
** Append those entries to mapped
      APPEND CORRESPONDING #( <fs_entities> ) TO mapped-travel.
    ENDLOOP.
** Get instance with TravelId initial
    DATA(entities_wo_travelId) = entities.
    DELETE entities_wo_travelId WHERE TravelId IS NOT INITIAL.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        =  DATA(number_range_return_code)
            returned_quantity =  DATA(number_range_returned_quantity)
        ).

        ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).
        DATA travel_id_max TYPE /dmo/travel_id..
        travel_id_max = number_range_key - number_range_returned_quantity.
        LOOP AT entities_wo_travelId INTO entity.
          travel_id_max += 1.
          entity-TravelId = travel_id_max.
          APPEND CORRESPONDING #( entity ) TO mapped-travel.
        ENDLOOP.
      CATCH cx_nr_object_not_found INTO DATA(lo_object_not_found).
        LOOP AT entities ASSIGNING <fs_entities>.
          APPEND VALUE #( %cid = <fs_entities>-%cid
                          %key = <fs_entities>-%key
                          %msg = lo_object_not_found
                           ) TO reported-travel.
          APPEND VALUE #( %cid = <fs_entities>-%cid
                          %key = <fs_entities>-%key
                          %fail-cause = if_abap_behv=>cause-conflict
                           ) TO failed-travel.
        ENDLOOP.
      CATCH cx_number_ranges INTO DATA(lo_number_ranges).
        LOOP AT entities ASSIGNING <fs_entities>.
          APPEND VALUE #( %cid = <fs_entities>-%cid
                          %key = <fs_entities>-%key
                          %msg = lo_number_ranges
                           ) TO reported-travel.

          APPEND VALUE #( %cid = <fs_entities>-%cid
                          %key = <fs_entities>-%key
                          %fail-cause = if_abap_behv=>cause-conflict
                           ) TO failed-travel.
        ENDLOOP.
    ENDTRY.
  ENDMETHOD.
  METHOD earlynumbering_cba_Booking.

    DATA: max_booking_id TYPE /dmo/booking_id.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FROM CORRESPONDING #( entities )
    LINK DATA(lt_bookings).


    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>) GROUP BY <travel>-TravelId.

      max_booking_id = REDUCE #( INIT max = CONV /dmo/booking_id( '0' )
                                 FOR booking IN lt_bookings USING KEY entity WHERE ( source-TravelId = <travel>-TravelId )
                                 NEXT max = COND /dmo/booking_id( WHEN booking-target-BookingId > max
                                                    THEN booking-target-BookingId
                                                    ELSE max )    ).

      max_booking_id = REDUCE #( INIT max = max_booking_id
                             FOR entity IN entities USING KEY entity WHERE ( TravelId = <travel>-TravelId )
                             FOR target IN entity-%target
                             NEXT max = COND /dmo/booking_id( WHEN target-BookingId > max
                                                THEN target-BookingId
                                                ELSE max )    ).

      " Assign new booking-ids if not already assigned
      LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_numbers>).
        APPEND CORRESPONDING #( <booking_wo_numbers> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<mapped_booking>).
        IF <booking_wo_numbers>-BookingId IS INITIAL.
          max_booking_id += 10 .
          <mapped_booking>-BookingId = max_booking_id .
        ENDIF.
      ENDLOOP.

    ENDLOOP.


  ENDMETHOD.


  METHOD copyTravel.

    DATA: travel_new        TYPE TABLE FOR CREATE zrtr_i_travel_m\\Travel,
          booking_cba_new   TYPE TABLE FOR CREATE zrtr_i_Travel_m\\Travel\_Booking,
          booksuppl_cba_new TYPE TABLE FOR CREATE zrtr_i_travel_m\\Booking\_BookSupplement.
** Check if cid is initial for factory actions

    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_initial_cid).

    ASSERT key_with_initial_cid IS INITIAL.

** Read travel based on keys

    READ ENTITIES OF zrtR_I_travel_m IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travel_read_result).

** Read all corresponding booking

    READ ENTITIES OF zrtR_i_travel_m IN LOCAL MODE
    ENTITY travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( travel_read_Result )
    RESULT DATA(bookings_read_Result).

** Read all corresponding booking supplements

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY booking BY \_BookSupplement
    ALL FIELDS WITH CORRESPONDING #( bookings_read_result )
    RESULT DATA(booksuppl_read_Result).

    LOOP AT keys INTO DATA(key).
** Read travel entity
      READ TABLE travel_Read_result ASSIGNING FIELD-SYMBOL(<travel>) WITH KEY id COMPONENTS  %tky = key-%tky.
      IF sy-subrc = 0.
** Fill travel container
        APPEND VALUE #( %cid = key-%cid
                        %data = CORRESPONDING #( <travel> EXCEPT travelid ) ) TO travel_new ASSIGNING FIELD-SYMBOL(<travel_new>).

        <travel_new>-BeginDate = cl_abap_context_info=>get_system_date( ).
        <travel_new>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
        <travel_new>-OverallStatus = 'O'. "Set to open to allow an editable instance
        <travel_new>-Description = | RAVI - Copy from { <travel>-TravelId }|.

        APPEND VALUE #( %cid_ref = key-%cid ) TO booking_cba_new ASSIGNING FIELD-SYMBOL(<booking_cba>).

        LOOP AT bookings_read_Result ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity WHERE TravelId = <travel>-TravelId.

          APPEND VALUE #( %cid = | { key-%cid } && { <booking>-BookingId } |
                          %data = CORRESPONDING #( <booking> EXCEPT travelid ) ) TO <booking_cba>-%target ASSIGNING FIELD-SYMBOL(<booking_new>).

          <booking_new>-BookingStatus = 'N'.

          APPEND VALUE #( %cid_ref = | { key-%cid } && { <booking>-BookingId } | ) TO booksuppl_cba_new ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

          LOOP AT booksuppl_read_Result ASSIGNING FIELD-SYMBOL(<booksupplement>) USING KEY entity WHERE TravelId = <travel>-TravelId AND
                                                                                                        BookingId = <booking>-BookingId.
            APPEND VALUE #( %cid = | { key-%cid } && { <booking>-BookingId } && { <booksupplement>-BookingSupplementId } |
                             %data = CORRESPONDING #( <booksupplement> EXCEPT travelid bookingid )  ) TO <booksuppl_cba>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_new>).

          ENDLOOP.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus description )
    WITH travel_new
    CREATE BY \_Booking FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice CurrencyCode BookingStatus )
    WITH booking_cba_new
    ENTITY Booking
    CREATE BY \_BookSupplement FIELDS ( BookingSupplementId SupplementId price CurrencyCode )
    WITH booksuppl_cba_new
    MAPPED DATA(mapped_create).

    mapped-travel   =  mapped_create-travel .

  ENDMETHOD.

  METHOD reCalTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY travel
    FIELDS ( BookingFee OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    " Read all associated bookings and add them to the total price.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY travel BY \_Booking
    FIELDS ( FlightPrice CurrencyCode )
    WITH CORRESPONDING #( travels )
    RESULT DATA(bookings).

    " Read all associated booking supplements and add them to the total price.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY booking BY \_BookSupplement
    FIELDS ( Price CurrencyCode )
    WITH CORRESPONDING #( bookings )
    RESULT DATA(bookingSupplement).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      clear <travel>-TotalPrice.
      amounts_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
                                            currency_code = <travel>-CurrencyCode ) ).

      LOOP AT bookings INTO DATA(booking) USING KEY id WHERE TravelId = <travel>-TravelId
                                                           AND CurrencyCode IS NOT INITIAL.

        COLLECT VALUE ty_amount_per_currencycode( amount = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) INTO amounts_per_currencycode.

      ENDLOOP.

      LOOP AT bookingsupplement INTO DATA(bookSuppl) USING KEY id WHERE TravelId = <travel>-TravelId
                                                         AND CurrencyCode IS NOT INITIAL.

        COLLECT VALUE ty_amount_per_currencycode( amount = bookSuppl-Price
                                                  currency_code = bookSuppl-CurrencyCode ) INTO amounts_per_currencycode.

      ENDLOOP.

      DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.


      LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).
        IF amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
           EXPORTING
             iv_amount                   =  amount_per_currencycode-amount
             iv_currency_code_source     =  amount_per_currencycode-currency_code
             iv_currency_code_target     =  <travel>-CurrencyCode
             iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
           IMPORTING
             ev_amount                   = DATA(total_booking_price_per_curr)
          ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys (  %tky = key-%tky
                                     OverallStatus = 'A' )   )
    MAPPED DATA(mapped_updated).

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                               %param = travel        ) )  .

  ENDMETHOD.


  METHOD rejectTravel.


    MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
  ENTITY Travel
  UPDATE FIELDS ( OverallStatus )
  WITH VALUE #( FOR key IN keys (  %tky = key-%tky
                                   OverallStatus = 'X' )   )
  MAPPED DATA(mapped_updated).

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                               %param = travel        ) )  .


  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travels)
    FAILED failed.

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %features-%action-acceptTravel = COND #( WHEN travel-OverallStatus = 'A'
                                                                                       THEN if_abap_behv=>fc-o-disabled
                                                                                       ELSE if_abap_behv=>fc-o-enabled  )
                                              %features-%action-rejectTravel = COND #( WHEN travel-OverallStatus = 'X'
                                                                                       THEN if_abap_behv=>fc-o-disabled
                                                                                       ELSE if_abap_behv=>fc-o-enabled )
                                              %features-%assoc-_Booking =  COND #( WHEN travel-OverallStatus = 'X'
                                                                                       THEN if_abap_behv=>fc-o-disabled
                                                                                       ELSE if_abap_behv=>fc-o-enabled )
                                                                                        ) ).

  ENDMETHOD.

  METHOD validateAgency.

    " Read relevant travel instance data
    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY travel
     FIELDS ( AgencyId )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    " Optimization of DB select: extract distinct non-initial agency IDs
    agencies = CORRESPONDING #(  travels DISCARDING DUPLICATES MAPPING agency_id = agencyid EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.
    IF  agencies IS NOT INITIAL.

      " check if agency ID exist
      SELECT FROM /dmo/agency FIELDS agency_id
        FOR ALL ENTRIES IN @agencies
        WHERE agency_id = @agencies-agency_id
        INTO TABLE @DATA(agencies_db).
    ENDIF.

    " Raise msg for non existing and initial agency id
    LOOP AT travels INTO DATA(travel).
      IF travel-agencyid IS INITIAL
         OR NOT line_exists( agencies_db[ agency_id = travel-agencyid ] ).

        APPEND VALUE #(  %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky               = travel-%tky
                        %msg               = NEW /dmo/cm_flight_messages(
                        textid    = /dmo/cm_flight_messages=>agency_unkown
                        agency_id = travel-agencyid
                        severity  = if_abap_behv_message=>severity-error )
                        %element-agencyid = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateBookingFee.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
        ENTITY travel
          FIELDS ( bookingfee )
          WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel) WHERE bookingfee < 0.
      " Raise message for booking fee < 0
      APPEND VALUE #( %tky                 = travel-%tky ) TO failed-travel.
      APPEND VALUE #( %tky                 = travel-%tky
                      %msg                 = NEW /dmo/cm_flight_messages(
                                                     textid      = /dmo/cm_flight_messages=>booking_fee_invalid
                                                     severity    = if_abap_behv_message=>severity-error )
                      %element-bookingfee = if_abap_behv=>mk-on
                    ) TO reported-travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY travel
        FIELDS ( currencycode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    DATA: currencies TYPE SORTED TABLE OF I_Currency WITH UNIQUE KEY currency.

    currencies = CORRESPONDING #(  travels DISCARDING DUPLICATES MAPPING currency = currencycode EXCEPT * ).
    DELETE currencies WHERE currency IS INITIAL.

    IF currencies IS NOT INITIAL.
      SELECT FROM I_Currency FIELDS currency
        FOR ALL ENTRIES IN @currencies
        WHERE currency = @currencies-currency
        INTO TABLE @DATA(currency_db).
    ENDIF.


    LOOP AT travels INTO DATA(travel).
      IF travel-currencycode IS INITIAL.
        " Raise message for empty Currency
        APPEND VALUE #( %tky                   = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky                   = travel-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_required
                                                        severity  = if_abap_behv_message=>severity-error )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ELSEIF NOT line_exists( currency_db[ currency = travel-currencycode ] ).
        " Raise message for not existing Currency
        APPEND VALUE #( %tky                   = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky                   = travel-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid        = /dmo/cm_flight_messages=>currency_not_existing
                                                        severity      = if_abap_behv_message=>severity-error
                                                        currency_code = travel-currencycode )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validateCustomer.


    READ ENTITIES OF zrtR_i_travel_m IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA: customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @customers
      WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(customers_db).

      LOOP AT travels INTO DATA(travel).
        IF travel-CustomerId IS INITIAL OR NOT line_exists( customers_db[  customer_id = travel-CustomerId ] ).
          failed-travel = VALUE #( BASE failed-travel  ( %tky = travel-%tky  ) ).
          reported-travel = VALUE #( BASE reported-travel ( %tky = travel-%tky
                                                            %msg = NEW /dmo/cm_flight_messages(
                                                                                                customer_id = travel-CustomerId
                                                                                                textid      = /dmo/cm_flight_messages=>customer_unkown
                                                                                                severity    = if_abap_behv_message=>severity-error )
                                                            %element-customerid = if_abap_behv=>mk-on )  ).
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
          ENTITY travel
            FIELDS ( begindate enddate )
            WITH CORRESPONDING #( keys )
          RESULT DATA(travels).
    LOOP AT travels INTO DATA(travel).
      IF travel-enddate < travel-begindate.  "end_date before begin_date
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                   textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                   severity   = if_abap_behv_message=>severity-error
                                   begin_date = travel-begindate
                                   end_date   = travel-enddate
                                   travel_id  = travel-travelid )
                        %element-begindate   = if_abap_behv=>mk-on
                        %element-enddate     = if_abap_behv=>mk-on
                     ) TO reported-travel.
      ELSEIF travel-begindate < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future
        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid   = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                    severity = if_abap_behv_message=>severity-error
                                    begin_date = travel-begindate )
                        %element-begindate  = if_abap_behv=>mk-on
                        %element-enddate    = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD validateStatus.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
          ENTITY travel
            FIELDS ( overallstatus )
            WITH CORRESPONDING #( keys )
          RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      CASE travel-overallstatus.
        WHEN 'O'.  " Open
        WHEN 'X'.  " Cancelled
        WHEN 'A'.  " Accepted

        WHEN OTHERS.
          APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>status_invalid
                                     severity = if_abap_behv_message=>severity-error
                                     status = travel-overallstatus )
                          %element-overallstatus = if_abap_behv=>mk-on
                        ) TO reported-travel.
      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Travel
    EXECUTE reCalTotalPrice
    FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
