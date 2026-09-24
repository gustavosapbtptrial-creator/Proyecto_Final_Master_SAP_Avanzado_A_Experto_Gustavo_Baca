@EndUserText.label: 'Incident history'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZR_INCT_H_327
  as select from zdt_inct_h_327 as History
    association to parent ZR_INCT_327 as _Incident
      on $projection.IncUuid = _Incident.IncUuid
{
  key History.his_uuid               as HisUuid,
      History.inc_uuid               as IncUuid,
      History.his_id                 as HisId,
      History.previous_status        as PreviousStatus,
      History.new_status             as NewStatus,
      History.text                   as Text,
      History.local_created_by       as LocalCreatedBy,
      History.local_created_at       as LocalCreatedAt,
      History.local_last_changed_by  as LocalLastChangedBy,
      History.local_last_changed_at  as LocalLastChangedAt,
      History.last_changed_at        as LastChangedAt,

      _Incident
}
