@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for root travel entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define root view entity ZTECH_RS_TRAVEL_PROCESSOR
  as projection on ztech_rs_travel
{
  key TravelId,
      AgencyId,
      CustomerId,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      AgencyName,
      CustomerName,
      StatusText,
      StatusColour,
      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZTECH_RS_BOOKING_PROCESSOR,
      _Currency,
      _Customer,
      _OverallStatus
}
