@EndUserText.label: 'Incident consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_DT_INCT_327
  provider contract transactional_query
  as projection on ZR_INCT_327
{
  key IncUuid,
      IncidentId,
      Title,
      Description,
      Status,
      Priority,
      Responsible,
      CreationDate,
      ChangedDate,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _History : redirected to composition child ZC_DT_INCT_H_327
}
