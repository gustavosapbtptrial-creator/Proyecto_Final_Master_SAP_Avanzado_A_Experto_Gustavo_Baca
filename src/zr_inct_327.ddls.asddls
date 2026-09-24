@EndUserText.label: 'Incident root'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZR_INCT_327
  as select from zdt_inct_327 as Incident
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
      Incident.local_created_by       as LocalCreatedBy,
      Incident.local_created_at       as LocalCreatedAt,
      Incident.local_last_changed_by  as LocalLastChangedBy,
      Incident.local_last_changed_at  as LocalLastChangedAt,
      Incident.last_changed_at        as LastChangedAt
}
