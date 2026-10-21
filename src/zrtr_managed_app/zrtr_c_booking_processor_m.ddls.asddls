@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RTR: Travel Processor - Booking Entity'
//@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity ZRTR_C_BOOKING_PROCESSOR_M
  as projection on ZRTR_I_BOOKING_M
{
      @Search.defaultSearchElement: true
  key TravelId,
      @Search.defaultSearchElement: true
  key BookingId,
      BookingDate,
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Customer', element: 'CustomerID' }}]
      @ObjectModel.text.element: ['CustomerName']
      CustomerId,
      _Customer.LastName        as CustomerName,
      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Carrier', element: 'AirlineID' }}]
      @ObjectModel.text.element: ['CarrierName']
      CarrierId,
      _Carrier.Name             as CarrierName,
      @Consumption.valueHelpDefinition: [ {entity: {name: '/DMO/I_Flight', element: 'ConnectionID'},
                                                useForValidation: true,
                                                additionalBinding: [ { localElement: 'FlightDate',   element: 'FlightDate' ,usage: #FILTER_AND_RESULT } ,
                                                                     { localElement: 'CarrierId',    element: 'AirlineID',usage: #FILTER_AND_RESULT} ,
                                                                     { localElement: 'FlightPrice',  element: 'Price' , usage: #FILTER_AND_RESULT },
                                                                     { localElement: 'CurrencyCode', element: 'CurrencyCode' , usage: #FILTER_AND_RESULT } ]
                                                  } ]
      ConnectionId,
      @Consumption.valueHelpDefinition: [ {entity: {name: '/DMO/I_Flight', element: 'FlightDate' },
                                           additionalBinding: [ { localElement: 'ConnectionID', element: 'ConnectionID'},
                                                                { localElement: 'CarrierId',    element: 'AirlineID'},
                                                                { localElement: 'FlightPrice',  element: 'Price' },
                                                                { localElement: 'CurrencyCode', element: 'CurrencyCode' }]}]
      FlightDate,
      FlightPrice,
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_Currency', element: 'Currency' }}]
      CurrencyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Booking_Status_VH', element: 'BookingStatus' }}]
      @ObjectModel.text.element: ['BookingStatusText']
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookSupplement : redirected to composition child ZRTR_C_BOOKSUPPL_PROCESSOR_M,
      _Carrier,
      _Connection,
      _Customer,
      _Travel         : redirected to parent ZRTR_C_TRAVEL_PROCESSOR_M
}
