@ClientHandling.type: #CLIENT_DEPENDENT
@AbapCatalog.deliveryClass: #APPLICATION_DATA
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RTR:Travel log details'
define table entity ZRTR_log_travel
{
  key change_id      : abap.raw(16);
  travel_id          : /dmo/travel_id;
  changing_operation : abap.char(10);
  changed_field_name : abap.char(32);
  changed_value      : abap.char(32);
  created_at         : timestampl;      
}
