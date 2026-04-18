@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root CDS entity for Travel Request'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
define root view entity ztech_rs_travel
  as select from /dmo/travel_m
  composition [0..*] of ztech_rs_booking             as _Booking
  association of one to one /dmo/agency              as _Agency        on $projection.AgencyId = _Agency.agency_id
  association of one to one /DMO/I_Customer          as _Customer      on $projection.CustomerId = _Customer.CustomerID
  association of one to one I_Currency               as _Currency      on $projection.CurrencyCode = _Currency.Currency
  association of one to one /DMO/I_Overall_Status_VH as _OverallStatus on $projection.OverallStatus = _OverallStatus.OverallStatus
{
      @ObjectModel.text.element: [ 'Description' ]
  key travel_id                                                        as TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      agency_id                                                        as AgencyId,
      _Agency.name                                                     as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      customer_id                                                      as CustomerId,
      concat(concat( _Customer.FirstName, ' '), _Customer.LastName)    as CustomerName,
      begin_date                                                       as BeginDate,
      end_date                                                         as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee                                                      as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price                                                      as TotalPrice,
      currency_code                                                    as CurrencyCode,
      description                                                      as Description,
      @EndUserText.label: 'Overall Status'
      overall_status                                                   as OverallStatus,
      case overall_status
       when 'O' then 2
       when 'A' then 3
       when 'X' then 1
       else 1
       end as StatusColour,
      _OverallStatus._Text[ Language = $session.system_language ].Text as StatusText,
      @Semantics.user.createdBy: true
      created_by                                                       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                                                       as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                                                  as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      -->Will be traeted as eTAG
      last_changed_at                                                  as LastChangedAt,
      --Expose the composition
      _Booking,
      _Agency,
      _Customer,
      _Currency,
      _OverallStatus
}
