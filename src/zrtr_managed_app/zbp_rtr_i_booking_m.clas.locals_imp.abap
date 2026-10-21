CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Booksupplem FOR NUMBERING
       entities FOR CREATE Booking\_Booksupplement.
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR Booking RESULT result.
    METHODS validateconnection FOR VALIDATE ON SAVE
       keys FOR booking~validateconnection.

    METHODS validatecurrencycode FOR VALIDATE ON SAVE
       keys FOR booking~validatecurrencycode.

    METHODS validatecustomer FOR VALIDATE ON SAVE
       keys FOR booking~validatecustomer.

    METHODS validateflightprice FOR VALIDATE ON SAVE
       keys FOR booking~validateflightprice.

    METHODS validatestatus FOR VALIDATE ON SAVE
       keys FOR booking~validatestatus.
    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
       keys FOR booking~calculatetotalprice.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Booksupplem.

    DATA: max_booking_suppl_id TYPE /dmo/booking_supplement_id .

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
    ENTITY Booking BY \_BookSupplement
    FROM CORRESPONDING #( entities )
    LINK DATA(book_supplements).

    " Loop over all unique tky (TravelID + BookingID)
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>) GROUP BY <booking>-%tky.

** find the max_booking supplement id from database
      max_booking_suppl_id = REDUCE  /dmo/booking_supplement_id( INIT max = CONV /dmo/booking_supplement_id( '0' )
                                                                 FOR book_supplement IN book_supplements USING KEY entity WHERE ( source-%tky = <booking>-%tky )
                                                                 NEXT max = COND /dmo/booking_supplement_id( WHEN book_supplement-target-BookingSupplementId > max
                                                                                                             THEN book_supplement-target-BookingSupplementId
                                                                                                             ELSE max )
                                                               ).
** find the max_booking supplement id from input



      max_booking_suppl_id = REDUCE /dmo/booking_supplement_id( INIT max = max_booking_suppl_id
                                                                FOR entity IN entities USING KEY entity WHERE ( %tky = <booking>-%tky )
                                                                FOR target IN entity-%target
                                                                NEXT max =  COND /dmo/booking_supplement_id( WHEN target-BookingSupplementId > max
                                                                                                             THEN target-BookingSupplementId
                                                                                                             ELSE max )
                                                               ).

      LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_numbers>).
        APPEND CORRESPONDING #( <booksuppl_wo_numbers> ) TO mapped-bookingsupplement ASSIGNING FIELD-SYMBOL(<mapped_booksuppl>).
        IF <booksuppl_wo_numbers>-BookingSupplementId IS INITIAL.
          max_booking_suppl_id += 1.
          <mapped_booksuppl>-BookingSupplementId += max_booking_suppl_id.
        ENDIF.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.


    READ ENTITIES OF zrtr_i_Travel_m IN LOCAL MODE
    ENTITY booking
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(bookings)
    FAILED failed.

    result = VALUE #( FOR booking IN bookings (  %tky = booking-%tky
                                                 %assoc-_booksupplement = COND #( WHEN booking-bookingstatus = 'B'
                                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                                   ELSE if_abap_behv=>fc-o-enabled ) ) ).

  ENDMETHOD.

  METHOD validateConnection.

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
          ENTITY Booking
            FIELDS ( bookingid carrierid connectionid flightdate )
            WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).
      " Raise message for non existing airline ID
      IF <booking>-carrierid IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                = <booking>-%tky
                        %msg                = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_airline_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-carrierid = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " Raise message for non existing connection ID
      IF <booking>-connectionid IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = <booking>-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_connection_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                  = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-connectionid = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " Raise message for non existing flight date
      IF <booking>-flightdate IS INITIAL.
        APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = <booking>-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_flight_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-flightdate = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
      " check if flight connection exists
      IF <booking>-carrierid IS NOT INITIAL AND
         <booking>-connectionid IS NOT INITIAL AND
         <booking>-flightdate IS NOT INITIAL.
        SELECT SINGLE Carrier_ID, Connection_ID, Flight_Date   FROM /dmo/flight  WHERE  carrier_id    = @<booking>-carrierid
                                                               AND  connection_id = @<booking>-connectionid
                                                               AND  flight_date   = @<booking>-flightdate
                                                               INTO  @DATA(flight).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <booking>-%tky ) TO failed-booking.
          APPEND VALUE #( %tky                   = <booking>-%tky
                          %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid      = /dmo/cm_flight_messages=>no_flight_exists
                                                                carrier_id  = <booking>-carrierid
                                                                flight_date = <booking>-flightdate
                                                                severity    = if_abap_behv_message=>severity-error )
                          %path                  = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = <booking>-%tky ]-target-%tky )
                          %element-flightdate   = if_abap_behv=>mk-on
                          %element-carrierid    = if_abap_behv=>mk-on
                          %element-connectionid = if_abap_behv=>mk-on
                        ) TO reported-booking.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
          ENTITY booking
            FIELDS ( currencycode )
            WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).
    DATA: currencies TYPE SORTED TABLE OF i_currency WITH UNIQUE KEY currency.
    currencies = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING currency = currencycode EXCEPT * ).
    DELETE currencies WHERE currency IS INITIAL.
    IF currencies IS NOT INITIAL.
      SELECT FROM i_currency FIELDS currency
        FOR ALL ENTRIES IN @currencies
        WHERE currency = @currencies-currency
        INTO TABLE @DATA(currency_db).
    ENDIF.
    LOOP AT bookings INTO DATA(booking).
      IF booking-currencycode IS INITIAL.
        " Raise message for empty Currency
        APPEND VALUE #( %tky                   = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = booking-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_required
                                                        severity  = if_abap_behv_message=>severity-error )
                        %element-currencycode = if_abap_behv=>mk-on
                        %path                  = VALUE #(  travel-travelid    = booking-travelid )
                      ) TO reported-booking.
      ELSEIF NOT line_exists( currency_db[ currency = booking-currencycode ] ).
        " Raise message for not existing Currency
        APPEND VALUE #( %tky                   = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                   = booking-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_not_existing
                                                        severity  = if_abap_behv_message=>severity-error
                                                        currency_code = booking-currencycode )
                        %path                  = VALUE #(  travel-travelid    = booking-travelid )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-booking.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
         ENTITY Booking
           FIELDS ( customerid )
           WITH CORRESPONDING #( keys )
       RESULT DATA(bookings).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.
    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING customer_id = customerid EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.
    IF  customers IS NOT INITIAL.
      " Check if customer ID exists
      SELECT FROM /dmo/customer FIELDS customer_id
                                FOR ALL ENTRIES IN @customers
                                WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(valid_customers).
    ENDIF.
    " Raise message for non existing and initial customer id
    LOOP AT bookings INTO DATA(booking).
      IF booking-customerid IS  INITIAL.
        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = booking-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_customer_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = booking-%tky ]-target-%tky )
                        %element-customerid = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ELSEIF booking-customerid IS NOT INITIAL AND NOT line_exists( valid_customers[ customer_id = booking-customerid ] ).
        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
        APPEND VALUE #( %tky                 = booking-%tky
                        %msg                 = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>customer_unkown
                                                                customer_id = booking-customerid
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                = VALUE #( travel-%tky = travel_booking_links[ KEY id  source-%tky = booking-%tky ]-target-%tky )
                        %element-customerid = if_abap_behv=>mk-on
                       ) TO reported-booking.
      ENDIF.
    ENDLOOP.




  ENDMETHOD.

  METHOD validateFlightPrice.

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
          ENTITY booking
            FIELDS ( flightprice )
            WITH CORRESPONDING #( keys )
          RESULT DATA(bookings).

    READ ENTITIES OF  zrtr_I_Travel_M IN LOCAL MODE
      ENTITY Booking BY \_Travel
        FROM CORRESPONDING #( bookings )
      LINK DATA(travel_booking_links).

    LOOP AT bookings INTO DATA(booking) WHERE flightprice < 0.
      " Raise message for flight price < 0
      APPEND VALUE #( %tky                  = booking-%tky ) TO failed-booking.
      APPEND VALUE #( %tky                  = booking-%tky
                      %msg                  = NEW /dmo/cm_flight_messages(
                                                     textid      = /dmo/cm_flight_messages=>flight_price_invalid
                                                     severity    = if_abap_behv_message=>severity-error )
                      %element-flightprice = if_abap_behv=>mk-on
                      %path                 = VALUE #( travel-%tky = travel_booking_links[ KEY id source-%tky = booking-%tky ]-target-%tky )
                    ) TO reported-booking.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatus.

    READ ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
         ENTITY booking
           FIELDS ( bookingstatus )
           WITH CORRESPONDING #( keys )
         RESULT DATA(bookings).
    LOOP AT bookings INTO DATA(booking).
      CASE booking-bookingstatus.
        WHEN 'N'.  " New
        WHEN 'X'.  " Canceled
        WHEN 'B'.  " Booked
        WHEN OTHERS.
          APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.
          APPEND VALUE #( %tky = booking-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>status_invalid
                                     status = booking-bookingstatus
                                     severity = if_abap_behv_message=>severity-error )
                          %element-bookingstatus = if_abap_behv=>mk-on
                          %path = VALUE #( travel-travelid    = booking-travelid )
                        ) TO reported-booking.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD calculateTotalPrice.


    DATA: travel_ids TYPE STANDARD TABLE OF zrtr_i_travel_m WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId  ).

  MODIFY ENTITIES OF zrtr_i_travel_m IN LOCAL MODE
  ENTITY Travel
  EXECUTE reCalTotalPrice
  FROM CORRESPONDING #( travel_ids ).


  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

