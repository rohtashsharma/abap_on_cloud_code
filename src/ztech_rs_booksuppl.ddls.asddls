@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supliment Child entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ztech_rs_booksuppl
  as select from /dmo/booksuppl_m
  association        to parent ztech_rs_booking as _Booking        on  $projection.TravelId  = _Booking.TravelId
                                                                   and $projection.BookingId = _Booking.BookingId
  association [1..1] to ztech_rs_travel         as _Travel         on  $projection.TravelId = _Travel.TravelId
  association [1..1] to /DMO/I_Supplement       as _Suppliment     on  $projection.SupplementId = _Suppliment.SupplementID
  association [1..*] to /DMO/I_SupplementText   as _SupplimentText on  $projection.SupplementId = _SupplimentText.SupplementID
{
  key /dmo/booksuppl_m.travel_id             as TravelId,
  key /dmo/booksuppl_m.booking_id            as BookingId,
  key /dmo/booksuppl_m.booking_supplement_id as BookingSupplementId,
      /dmo/booksuppl_m.supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      /dmo/booksuppl_m.price                 as Price,
      /dmo/booksuppl_m.currency_code         as CurrencyCode,
      @Semantics.systemDateTime.lastChangedAt: true
      /dmo/booksuppl_m.last_changed_at       as LastChangedAt,
      _Booking,
      _Travel,
      _Suppliment,
      _SupplimentText
}
