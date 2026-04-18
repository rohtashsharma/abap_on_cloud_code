@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Processor projection entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
define view entity ZTECH_RS_BOOKING_PROCESSOR
  as projection on ztech_rs_booking
{
  key TravelId,
  key BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookingSuppl : redirected to composition child ZTECH_RS_BOOKSUPP_PROCESSOR,
      _Carrier,
      _Connection,
      _customer,
      _Travel       : redirected to parent ZTECH_RS_TRAVEL_PROCESSOR
}
