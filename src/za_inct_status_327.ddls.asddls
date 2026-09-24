@EndUserText.label: 'Change incident status parameters'
define abstract entity ZA_INCT_STATUS_327
{
  @EndUserText.label: 'New Status'
  NewStatus  : zde_status_327;

  @EndUserText.label: 'Observation'
  Observation : abap.char(80);
}
