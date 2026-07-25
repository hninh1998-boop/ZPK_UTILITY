CLASS zcl_utility_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CLASS-METHODS read_entities_note
      IMPORTING
        out TYPE REF TO if_oo_adt_classrun_out.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_utility_eml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    "Read Entitites
    read_entities_note( out = out ).
  ENDMETHOD.




















  METHOD read_entities_note.
    DATA: lv_od TYPE string VALUE '0080000005'.

    READ ENTITIES OF I_OutboundDeliveryTP FORWARDING PRIVILEGED
      ENTITY OutboundDelivery
      BY \_Text
      ALL FIELDS WITH VALUE #( ( OutboundDelivery = lv_od ) )
      RESULT DATA(lt_text)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    out->write( lt_text ).

    IF ls_failed IS NOT INITIAL.
      out->write( 'FAILED:' ).
      out->write( ls_failed ).
    ENDIF.

    IF ls_reported IS NOT INITIAL.
      out->write( 'REPORTED:' ).
      out->write( ls_reported ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
