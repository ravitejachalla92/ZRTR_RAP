@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RTR:Travel Approver - Booking Entity'
@Metadata.allowExtensions: true
//@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZRTR_C_BOOKING_APPROVER_M
  as projection on ZRTR_I_BOOKING_M
{
      @Search.defaultSearchElement: true
  key TravelId,
      @Search.defaultSearchElement: true
  key BookingId,
      BookingDate,
      @ObjectModel.text.element: ['CustomerName']
      @Search.defaultSearchElement: true
      CustomerId,
      _Customer.LastName        as CustomerName,
      CarrierId,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Booking_Status_VH', element: 'BookingStatus' }}]
      @ObjectModel.text.element: ['BookingStatusText']
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookSupplement,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent ZRTR_C_TRAVEL_APPROVER_M
}
