@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Suppliment processor projection entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
define view entity ZTECH_RS_BOOKSUPP_PROCESSOR
  as projection on ztech_rs_booksuppl
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZTECH_RS_BOOKING_PROCESSOR,
      _Suppliment,
      _SupplimentText,
      _Travel  : redirected to ZTECH_RS_TRAVEL_PROCESSOR
}
