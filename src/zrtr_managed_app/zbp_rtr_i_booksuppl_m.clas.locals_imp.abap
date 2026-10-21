CLASS lhc_bookingsupplement DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
       keys FOR BookingSupplement~validateCurrencyCode.

    METHODS validatePrice FOR VALIDATE ON SAVE
       keys FOR BookingSupplement~validatePrice.

    METHODS validateSupplement FOR VALIDATE ON SAVE
       keys FOR BookingSupplement~validateSupplement.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      keys FOR BookingSupplement~calculateTotalPrice.

ENDCLASS.

CLASS lhc_bookingsupplement IMPLEMENTATION.

  METHOD validateCurrencyCode.

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
              ENTITY BookingSupplement
              FIELDS ( currencycode )
              WITH CORRESPONDING #( keys )
              RESULT DATA(booking_supplements).

    DATA: currencies TYPE SORTED TABLE OF I_Currency WITH UNIQUE KEY currency.

    currencies = CORRESPONDING #( booking_supplements DISCARDING DUPLICATES MAPPING currency = currencycode EXCEPT * ).

    DELETE currencies WHERE currency IS INITIAL.

    IF currencies IS NOT INITIAL.
      SELECT FROM I_Currency FIELDS currency
      FOR ALL ENTRIES IN @currencies
      WHERE currency = @currencies-currency
      INTO TABLE @DATA(currency_db).
    ENDIF.

    LOOP AT booking_supplements INTO DATA(booking_supplement).
      IF booking_supplement-currencycode IS INITIAL.
        " Raise message for empty Currency
        APPEND VALUE #( %tky                   = booking_supplement-%tky ) TO failed-bookingsupplement.
        APPEND VALUE #( %tky                   = booking_supplement-%tky
        %msg                   = NEW /dmo/cm_flight_messages(
        textid    = /dmo/cm_flight_messages=>currency_required
        severity  = if_abap_behv_message=>severity-error )
        %element-currencycode = if_abap_behv=>mk-on
        %path                  = VALUE #( travel-travelid    = booking_supplement-travelid
        booking-bookingid  = booking_supplement-bookingid )
        ) TO reported-bookingsupplement.

      ELSEIF NOT line_exists( currency_db[ currency = booking_supplement-currencycode ] ).
        " Raise message for not existing Currency
        APPEND VALUE #( %tky                   = booking_supplement-%tky ) TO failed-bookingsupplement.
        APPEND VALUE #( %tky                   = booking_supplement-%tky
        %msg                   = NEW /dmo/cm_flight_messages(
        textid        = /dmo/cm_flight_messages=>currency_not_existing
        severity      = if_abap_behv_message=>severity-error
        currency_code = booking_supplement-currencycode )
        %element-currencycode = if_abap_behv=>mk-on
        ) TO reported-bookingsupplement.
      ENDIF.
    ENDLOOP.

ENDMETHOD.

METHOD validatePrice.

 READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement
        FIELDS ( price )
        WITH CORRESPONDING #( keys )
      RESULT DATA(booking_supplements).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement BY \_Booking
        FROM CORRESPONDING #( booking_supplements )
      LINK DATA(booksuppl_booking_links).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement BY \_Travel
        FROM CORRESPONDING #( booking_supplements )
      LINK DATA(booksuppl_travel_links).

    LOOP AT booking_supplements INTO DATA(book_suppl) WHERE price < 0.
      " Raise message for supplement price < 0
      APPEND VALUE #( %tky                  = book_suppl-%tky ) TO failed-bookingsupplement.
      APPEND VALUE #( %tky                  = book_suppl-%tky
                      %msg                  = NEW /dmo/cm_flight_messages(
                                                     textid      = /dmo/cm_flight_messages=>suppl_price_invalid
                                                     severity    = if_abap_behv_message=>severity-error )
                      %path                  = VALUE #( booking-%tky = booksuppl_booking_links[ KEY id  source-%tky = book_suppl-%tky ]-target-%tky
                                                        travel-%tky  = booksuppl_travel_links[  KEY id  source-%tky = book_suppl-%tky ]-target-%tky )
                      %element-price = if_abap_behv=>mk-on
                    ) TO reported-bookingsupplement.
    ENDLOOP.

ENDMETHOD.

METHOD validateSupplement.

 READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement
        FIELDS ( SupplementId )
        WITH CORRESPONDING #(  keys )
      RESULT DATA(bookingsupplements)
      FAILED DATA(read_failed).

    failed = CORRESPONDING #( DEEP read_failed ).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement BY \_Booking
        FROM CORRESPONDING #( bookingsupplements )
      LINK DATA(booksuppl_booking_links).

    READ ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY BookingSupplement BY \_Travel
        FROM CORRESPONDING #( bookingsupplements )
      LINK DATA(booksuppl_travel_links).


    DATA supplements TYPE SORTED TABLE OF /dmo/supplement WITH UNIQUE KEY supplement_id.

    supplements = CORRESPONDING #( bookingsupplements DISCARDING DUPLICATES MAPPING supplement_id = supplementid EXCEPT * ).
    DELETE supplements WHERE supplement_id IS INITIAL.

    IF  supplements IS NOT INITIAL.
      " Check if supplement ID exists
      SELECT FROM /dmo/supplement FIELDS supplement_id
                                  FOR ALL ENTRIES IN @supplements
                                  WHERE supplement_id = @supplements-supplement_id
      INTO TABLE @DATA(valid_supplements).
    ENDIF.

    LOOP AT bookingsupplements ASSIGNING FIELD-SYMBOL(<bookingsupplement>).

      IF <bookingsupplement>-supplementid IS  INITIAL.

        APPEND VALUE #( %tky = <bookingsupplement>-%tky ) TO failed-bookingsupplement.
        APPEND VALUE #( %tky                   = <bookingsupplement>-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_supplement_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                  = VALUE #( booking-%tky = booksuppl_booking_links[ KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                          travel-%tky  = booksuppl_travel_links[  KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-supplementid = if_abap_behv=>mk-on
                       ) TO reported-bookingsupplement.


      ELSEIF <bookingsupplement>-supplementid IS NOT INITIAL AND NOT line_exists( valid_supplements[ supplement_id = <bookingsupplement>-supplementid ] ).

        APPEND VALUE #(  %tky = <bookingsupplement>-%tky ) TO failed-bookingsupplement.
        APPEND VALUE #( %tky                   = <bookingsupplement>-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>supplement_unknown
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                  = VALUE #( booking-%tky = booksuppl_booking_links[ KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                          travel-%tky = booksuppl_travel_links[  KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-supplementid = if_abap_behv=>mk-on
                       ) TO reported-bookingsupplement.
      ENDIF.

    ENDLOOP.


ENDMETHOD.

  METHOD calculateTotalPrice.


    DATA: travel_ids TYPE STANDARD TABLE OF zrtr_i_travel_m WITH UNIQUE HASHED KEY key COMPONENTS travelid.

    travel_ids = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING travelid = travelid ).
    MODIFY ENTITIES OF zrtr_I_Travel_M IN LOCAL MODE
      ENTITY Travel
        EXECUTE reCalTotalPrice
        FROM CORRESPONDING #( travel_ids ).


  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

