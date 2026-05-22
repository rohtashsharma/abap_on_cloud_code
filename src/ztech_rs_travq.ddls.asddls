@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Draft query view for ZTECH_RS_DTRAV'
define root view entity ztech_rs_travq
  as select from ztech_rs_dtrav
{
  key travelid as TravelId,
  agencyid as AgencyId,
  agencyname as AgencyName,
  customerid as CustomerId,
  customername as CustomerName,
  begindate as BeginDate,
  enddate as EndDate,
  bookingfee as BookingFee,
  totalprice as TotalPrice,
  currencycode as CurrencyCode,
  description as Description,
  overallstatus as OverallStatus,
  statuscolour as StatusColour,
  statustext as StatusText,
  createdby as CreatedBy,
  createdat as CreatedAt,
  lastchangedby as LastChangedBy,
  lastchangedat as LastChangedAt,
  draftentitycreationdatetime as draftentitycreationdatetime,
  draftentitylastchangedatetime as draftentitylastchangedatetime,
  draftadministrativedatauuid as draftadministrativedatauuid,
  draftentityoperationcode as draftentityoperationcode,
  hasactiveentity as hasactiveentity,
  draftfieldchanges as draftfieldchanges
}
