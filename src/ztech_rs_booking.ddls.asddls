@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking CDS entity as first child'
@Metadata.ignorePropagatedAnnotations: true
define view entity ztech_rs_booking
  as select from /dmo/booking_m
  composition [0..*] of ztech_rs_booksuppl           as _BookingSuppl
  association        to parent ztech_rs_travel              as _Travel on  $projection.TravelId = _Travel.TravelId
  association of one to one /dmo/customer            as _customer      on  $projection.CustomerId = _customer.customer_id
  association of one to one /DMO/I_Carrier           as _Carrier       on  $projection.CarrierId = _Carrier.AirlineID
  association of one to one /DMO/I_Connection        as _Connection    on  $projection.CarrierId    = _Connection.AirlineID
                                                                       and $projection.ConnectionId = _Connection.ConnectionID
  association of one to one /DMO/I_Booking_Status_VH as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus
{
  key travel_id       as TravelId,
  key booking_id      as BookingId,
      booking_date    as BookingDate,
      customer_id     as CustomerId,
      carrier_id      as CarrierId,
      connection_id   as ConnectionId,
      flight_date     as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price    as FlightPrice,
      currency_code   as CurrencyCode,
      booking_status  as BookingStatus,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
      _BookingSuppl,
      _Travel,
      _customer,
      _Carrier,
      _Connection,
      _BookingStatus
}
