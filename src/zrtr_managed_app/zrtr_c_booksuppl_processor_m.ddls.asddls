@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RTR: Travel - Booking Suppl Entity'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZRTR_C_BOOKSUPPL_PROCESSOR_M
  as projection on ZRTR_I_BOOKSUPPL_M
{
      @Search.defaultSearchElement: true
  key TravelId,
      @Search.defaultSearchElement: true
  key BookingId,
      @Search.defaultSearchElement: true
  key BookingSupplementId,
      @Consumption.valueHelpDefinition: [ {entity: {name: '/DMO/I_SUPPLEMENT', element: 'SupplementID' } ,
                                               additionalBinding: [ { localElement: 'Price',  element: 'Price' },
                                                                    { localElement: 'CurrencyCode', element: 'CurrencyCode' }] }]
      @ObjectModel.text.element: ['SupplementDescription']
      SupplementId,
      _SupplementText.Description as SupplementDescription : localized,
      Price,
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_Currency', element: 'Currency' }}]
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZRTR_C_BOOKING_PROCESSOR_M,
      _Product,
      _SupplementText,
      _Travel  : redirected to ZRTR_C_TRAVEL_PROCESSOR_M
}
