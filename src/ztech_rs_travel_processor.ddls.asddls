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
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_TECH_RS_VE'
      @EndUserText.label: 'CO2 Tax'
      virtual CO2Tax: abap.int4,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_TECH_RS_VE'
      @EndUserText.label: 'Day of Travel'
      virtual dayOfFlight: abap.char(10),
      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZTECH_RS_BOOKING_PROCESSOR,
      _Currency,
      _Customer,
      _OverallStatus
}
