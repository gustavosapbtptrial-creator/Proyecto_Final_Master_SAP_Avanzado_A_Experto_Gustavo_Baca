@EndUserText.label: 'Incident root'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZR_INCT_327
  as select from zdt_inct_327 as Incident
    composition [0..*] of ZR_INCT_H_327 as _History
{
  key Incident.inc_uuid               as IncUuid,
      Incident.incident_id            as IncidentId,
      Incident.title                  as Title,
      Incident.description            as Description,
      Incident.status                 as Status,
      Incident.priority               as Priority,
      Incident.responsible            as Responsible,
      Incident.creation_date          as CreationDate,
      Incident.changed_date           as ChangedDate,

      @Semantics.user.createdBy: true
      Incident.local_created_by       as LocalCreatedBy,

      @Semantics.systemDateTime.createdAt: true
      Incident.local_created_at       as LocalCreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      Incident.local_last_changed_by  as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Incident.local_last_changed_at  as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      Incident.last_changed_at        as LastChangedAt,

      _History
}
