@EndUserText.label: 'Incident history consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_DT_INCT_H_327
  
  as projection on ZR_INCT_H_327
{
  key HisUuid,
      IncUuid,
      HisId,
      PreviousStatus,
      NewStatus,
      Text,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Incident : redirected to parent ZC_DT_INCT_327
}
