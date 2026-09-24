CLASS lsc_zr_inct_327 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_inct_327 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_incident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

METHODS setInitialValues FOR DETERMINE ON MODIFY
  IMPORTING keys FOR Incident~setInitialValues.
METHODS get_instance_features FOR INSTANCE FEATURES
  IMPORTING keys REQUEST requested_features FOR Incident RESULT result.

METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
  IMPORTING keys REQUEST requested_authorizations FOR Incident RESULT result.

METHODS changeStatus FOR MODIFY
  IMPORTING keys FOR ACTION Incident~changeStatus RESULT result.

ENDCLASS.

CLASS lhc_incident IMPLEMENTATION.

METHOD setInitialValues.

  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  SELECT MAX( incident_id )
    FROM zdt_inct_327
    INTO @DATA(lv_last_id).

  DATA(lv_next_id) = CONV i( lv_last_id ).

  DATA lt_updates TYPE TABLE FOR UPDATE ZR_INCT_327.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
    lv_next_id += 1.

    APPEND VALUE #(
      %tky         = <key>-%tky
      IncidentId   = CONV #( lv_next_id )
      Status       = 'OP'
      CreationDate = lv_today
      ChangedDate  = lv_today
    ) TO lt_updates.
  ENDLOOP.

  MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      UPDATE FIELDS ( IncidentId Status CreationDate ChangedDate )
      WITH lt_updates.

ENDMETHOD.

METHOD get_instance_features.

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( IncUuid Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents)
    FAILED failed.

  LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).

    "Un borrador nuevo todavía no tiene registro activo.
    SELECT SINGLE inc_uuid
      FROM zdt_inct_327
      WHERE inc_uuid = @<incident>-IncUuid
      INTO @DATA(lv_existing_uuid).

    DATA(lv_exists) = xsdbool( sy-subrc = 0 ).

    APPEND VALUE #(
      %tky = <incident>-%tky
      %action-changeStatus = COND #(
        WHEN lv_exists = abap_true
         AND <incident>-Status <> 'CN'
         AND <incident>-Status <> 'CO'
         AND <incident>-Status <> 'CL'
        THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled )
    ) TO result.

  ENDLOOP.

ENDMETHOD.

METHOD get_instance_authorizations.

  DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( Responsible )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents)
    FAILED failed.

  LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).

    DATA(lv_can_update) = xsdbool(
      lv_user = 'CB9980001327'
      OR lv_user = <incident>-Responsible ).

    APPEND VALUE #( %tky = <incident>-%tky )
      TO result ASSIGNING FIELD-SYMBOL(<authorization>).

IF requested_authorizations-%update = if_abap_behv=>mk-on
   OR requested_authorizations-%action-Edit = if_abap_behv=>mk-on.

      <authorization>-%update = COND #(
        WHEN lv_can_update = abap_true
        THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).

    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      <authorization>-%delete = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD changeStatus.

  DATA lt_updates TYPE TABLE FOR UPDATE ZR_INCT_327.
  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( IncUuid Status Responsible )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents)
    FAILED failed.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

    READ TABLE lt_incidents ASSIGNING FIELD-SYMBOL(<incident>)
      WITH KEY %tky = <key>-%tky.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DATA(lv_new_status) = <key>-%param-NewStatus.

    "La acción solo aplica a incidentes ya guardados.
    SELECT SINGLE inc_uuid
      FROM zdt_inct_327
      WHERE inc_uuid = @<incident>-IncUuid
      INTO @DATA(lv_existing_uuid).

    IF sy-subrc <> 0.
      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Guarda el incidente antes de cambiar su estado.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    "Rechazar códigos que no pertenecen al catálogo.
    IF lv_new_status <> 'OP'
       AND lv_new_status <> 'IP'
       AND lv_new_status <> 'PE'
       AND lv_new_status <> 'CO'
       AND lv_new_status <> 'CL'
       AND lv_new_status <> 'CN'.

      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'El estado indicado no es válido.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    IF lv_new_status = <incident>-Status.
      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'El incidente ya tiene ese estado.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    IF <incident>-Status = 'CN'
       OR <incident>-Status = 'CO'
       OR <incident>-Status = 'CL'.

      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Un incidente en estado final no puede cambiar.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    IF <incident>-Status = 'PE'
       AND ( lv_new_status = 'CO' OR lv_new_status = 'CL' ).

      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Un incidente pendiente no puede completarse ni cerrarse.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    IF lv_new_status = 'IP' AND <incident>-Responsible IS INITIAL.
      APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Asigna un responsable antes de pasar a En progreso.' )
      ) TO reported-Incident.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      %tky        = <key>-%tky
      Status      = lv_new_status
      ChangedDate = lv_today
    ) TO lt_updates.

  ENDLOOP.

  IF lt_updates IS INITIAL.
    RETURN.
  ENDIF.

  MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      UPDATE FIELDS ( Status ChangedDate )
      WITH lt_updates
    FAILED DATA(ls_update_failed)
    REPORTED DATA(ls_update_reported).

  APPEND LINES OF ls_update_failed-Incident TO failed-Incident.
  APPEND LINES OF ls_update_reported-Incident TO reported-Incident.

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      ALL FIELDS WITH CORRESPONDING #( lt_updates )
    RESULT DATA(lt_updated_incidents).

  result = VALUE #(
    FOR ls_incident IN lt_updated_incidents
    ( %tky   = ls_incident-%tky
      %param = ls_incident )
  ).

ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

