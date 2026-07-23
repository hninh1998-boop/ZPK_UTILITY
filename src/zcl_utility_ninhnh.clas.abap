CLASS zcl_utility_ninhnh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS formatted_currency
      IMPORTING
        iv_currencycode       TYPE waers
        iv_currency_raw       TYPE dmbtr
      EXPORTING
        ev_currency_formatted TYPE string.

    CLASS-METHODS get_address
      IMPORTING
        iv_bp      TYPE i_businesspartner-BusinessPartner
      EXPORTING
        ev_address TYPE string.

    CLASS-METHODS formatted_quantity
      IMPORTING
        iv_uom                TYPE I_UnitOfMeasure-UnitOfMeasure
        iv_quantity_raw       TYPE menge_d
      EXPORTING
        ev_quantity_formatted TYPE string.

    CLASS-METHODS get_uom_isocode
      IMPORTING
        iv_uom         TYPE I_UnitOfMeasure-UnitOfMeasure
      EXPORTING
        ev_uom_isocode TYPE I_UnitOfMeasure-UnitOfMeasureISOCode.

    CLASS-METHODS get_api_message
      IMPORTING
        iv_result      TYPE string
        iv_code        TYPE i
      EXPORTING
        ev_messagetype TYPE char1
        ev_message     TYPE char255.

    CLASS-METHODS convert_uome_to_uom
      IMPORTING
        iv_uom_e TYPE I_UnitOfMeasure-UnitOfMeasure_E
      EXPORTING
        ev_uom   TYPE I_UnitOfMeasure-UnitOfMeasure.

    CLASS-METHODS formatted_amount
      IMPORTING
        iv_amount           TYPE I_SalesOrderItemPricingElement-conditionratevalue
      RETURNING
        VALUE(rv_formatted) TYPE string.

    CLASS-METHODS escape_xml
      IMPORTING
        iv_text          TYPE string
      RETURNING
        VALUE(rv_result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_utility_ninhnh IMPLEMENTATION.
  METHOD formatted_currency.
    DATA: lv_currency_raw LIKE iv_currency_raw.

    " Lấy số decimal places của currency
    SELECT SINGLE FROM I_Currency WITH PRIVILEGED ACCESS
      FIELDS Decimals
      WHERE Currency = @iv_currencycode
      INTO @DATA(lv_decimals).

    " SAP lưu mặc định 2 decimal → shift = 2 - actual decimals
    DATA(lv_shift) = 2 - lv_decimals.

    IF lv_shift > 0.
      " VND: shift = 2, chia 100 → 127000.00 → 1270.00 ??? SAI
      " Thực ra VND: 127000.00 trong DB = 127,000 VND hiển thị
      " Cần NHÂN cho 10^shift để ra đúng
      lv_currency_raw = iv_currency_raw * ipow( base = 10 exp = lv_shift ).
    ELSEIF lv_shift < 0.
      lv_currency_raw = iv_currency_raw / ipow( base = 10 exp = abs( lv_shift ) ).
    ENDIF.

    " Format thousand separator with dot
    DATA(lv_currency_raw2) = |{ CONV int8( lv_currency_raw ) }|.
    DATA(lv_len) = strlen( lv_currency_raw2 ).
    DATA(lv_formatted) = ||.
    DATA(lv_count) = 0.

    DO lv_len TIMES.
      lv_count += 1.
      DATA(lv_pos) = lv_len - lv_count.
      lv_formatted = |{ lv_currency_raw2+lv_pos(1) }{ lv_formatted }|.
      IF lv_count MOD 3 = 0 AND lv_pos > 0.
        lv_formatted = |.{ lv_formatted }|.
      ENDIF.
    ENDDO.

    ev_currency_formatted = |{ lv_formatted }|.
  ENDMETHOD.





















  METHOD get_address.
    SELECT SINGLE FROM i_businesspartner
    FIELDS
        \_CurrentDefaultAddress-AddressID
    WHERE BusinessPartner = @iv_bp
    INTO @DATA(lv_addressid).
    CHECK sy-subrc = 0.

    SELECT SINGLE FROM i_address_2 WITH PRIVILEGED ACCESS
    LEFT JOIN I_CountryText
        ON I_CountryText~Language = @sy-langu
        AND I_CountryText~Country = i_address_2~Country
        FIELDS
            "Key fields
            i_address_2~AddressID,

            i_address_2~streetname AS Street1,
            i_address_2~streetprefixname1 AS Street2,
            i_address_2~streetprefixname2 AS Street3,
            i_address_2~streetsuffixname1 AS Street4,
            i_address_2~CityName AS City,
            i_address_2~Country,
            I_CountryText~CountryShortName AS CountryForeignName
        WHERE AddressID = @lv_addressid
        INTO @DATA(ls_address).
    CHECK sy-subrc = 0.

    DATA(lt_parts) = VALUE string_table(  ( CONV string( ls_address-street1 ) )
                                          ( CONV string( ls_address-street2 ) )
                                          ( CONV string( ls_address-street3 ) )
                                          ( CONV string( ls_address-street4 ) ) ).

    DELETE lt_parts WHERE table_line IS INITIAL.   " bỏ phần rỗng

    DATA(lv_country_name) = COND string( WHEN ls_address-country = 'VN'
                                         THEN |Việt Nam|
                                         ELSE CONV string( ls_address-countryforeignname ) ).

    APPEND CONV string( ls_address-city ) TO lt_parts.
    APPEND lv_country_name                TO lt_parts.
    DELETE lt_parts WHERE table_line IS INITIAL.   " bỏ phần rỗng
    ev_address = concat_lines_of( table = lt_parts sep = `, ` ).
  ENDMETHOD.
















  METHOD formatted_quantity.
    " Lấy số decimal hiển thị của Unit of Measure
    SELECT SINGLE FROM I_UnitOfMeasure WITH PRIVILEGED ACCESS
      FIELDS UnitOfMeasureDspNmbrOfDcmls
      WHERE UnitOfMeasure = @iv_uom
      INTO @DATA(lv_decimals).

    " QUAN không bị lỗi shift ngầm định 2 decimal như CURR
    " → giá trị raw đã đúng thập phân thật, chỉ cần làm tròn theo decimals hiển thị
    DATA(lv_factor) = ipow( base = 10 exp = lv_decimals ).
    DATA(lv_rounded) = round( val = iv_quantity_raw * lv_factor dec = 0 ) / lv_factor.

    " Xử lý dấu âm riêng
    DATA(lv_is_negative) = xsdbool( lv_rounded < 0 ).
    DATA(lv_abs) = abs( lv_rounded ).

    " Tách phần nguyên
    DATA(lv_integer_part) = trunc( lv_abs ).
    DATA(lv_integer_str) = |{ CONV int8( lv_integer_part ) }|.

    " Format thousand separator with dot cho phần nguyên
    DATA(lv_len) = strlen( lv_integer_str ).
    DATA(lv_formatted) = ||.
    DATA(lv_count) = 0.
    DO lv_len TIMES.
      lv_count += 1.
      DATA(lv_pos) = lv_len - lv_count.
      lv_formatted = |{ lv_integer_str+lv_pos(1) }{ lv_formatted }|.
      IF lv_count MOD 3 = 0 AND lv_pos > 0.
        lv_formatted = |.{ lv_formatted }|.
      ENDIF.
    ENDDO.

    " Format phần thập phân (nếu có decimals)
    IF lv_decimals > 0.
      DATA(lv_decimal_part) = ( lv_abs - lv_integer_part ) * lv_factor.
      DATA(lv_decimal_str) = |{ CONV int8( round( val = lv_decimal_part dec = 0 ) ) }|.
      " Pad leading zeros cho đủ số decimal
      lv_decimal_str = |{ lv_decimal_str WIDTH = lv_decimals ALIGN = RIGHT PAD = '0' }|.
      lv_formatted = |{ lv_formatted },{ lv_decimal_str }|.
    ENDIF.

    IF lv_is_negative = abap_true.
      lv_formatted = |-{ lv_formatted }|.
    ENDIF.

    ev_quantity_formatted = |{ lv_formatted }|.
  ENDMETHOD.






















  METHOD get_uom_isocode.
    SELECT SINGLE FROM I_UnitOfMeasure
    FIELDS UnitOfMeasureISOCode
    WHERE UnitOfMeasure = @iv_uom
    INTO @ev_uom_isocode.
  ENDMETHOD.



















  METHOD get_api_message.
    DATA: lv_msg  TYPE string,
          lv_code TYPE string.

    IF iv_code = 200
        OR iv_code = 201
        OR iv_code = 202
        OR iv_code = 204.
      "Success
      ev_messagetype = 'S'.
      ev_message     = 'Success'.
    ELSE.
      ev_messagetype = 'E'.

      CLEAR: lv_msg, lv_code.

      " 1. Thử parse dạng "message":"..." (string trực tiếp)
      FIND REGEX '"message"\s*:\s*"([^"]*)"' IN iv_result SUBMATCHES lv_msg.

      " 2. Nếu không match, thử dạng "message":{"value":"..."}
      IF sy-subrc <> 0 OR lv_msg IS INITIAL.
        FIND REGEX '"value"\s*:\s*"([^"]*)"' IN iv_result SUBMATCHES lv_msg.
      ENDIF.

      " 3. Lấy thêm error code nếu cần hiển thị
      FIND REGEX '"code"\s*:\s*"([^"]*)"' IN iv_result SUBMATCHES lv_code.

      IF lv_msg IS NOT INITIAL.
        IF lv_code IS NOT INITIAL.
          ev_message = |[{ lv_code }] { lv_msg }|.
        ELSE.
          ev_message = lv_msg.
        ENDIF.
      ELSE.
        ev_message = |API Error HTTP { iv_code }|.
      ENDIF.
    ENDIF.
  ENDMETHOD.























  METHOD convert_uome_to_uom.
    SELECT SINGLE FROM I_UnitOfMeasure
    FIELDS UnitOfMeasure
    WHERE UnitOfMeasure_E = @iv_uom_e
    INTO @ev_uom.
  ENDMETHOD.
























  METHOD formatted_amount.
    DATA(lv_integer)      = floor( iv_amount ).
    DATA(lv_amount_x100)  = iv_amount * 100.
    DATA(lv_int_x100)     = lv_integer * 100.
    DATA(lv_dec_int)      = CONV int4( lv_amount_x100 - lv_int_x100 ).

    " Format phần nguyên với dấu chấm ngăn cách hàng nghìn
    DATA(lv_int_str)   = |{ CONV int8( lv_integer ) }|.
    DATA(lv_len)       = strlen( lv_int_str ).
    DATA(lv_formatted) = ||.
    DATA(lv_count)     = 0.

    DO lv_len TIMES.
      lv_count += 1.
      DATA(lv_pos) = lv_len - lv_count.
      lv_formatted = |{ lv_int_str+lv_pos(1) }{ lv_formatted }|.
      IF lv_count MOD 3 = 0 AND lv_pos > 0.
        lv_formatted = |.{ lv_formatted }|.
      ENDIF.
    ENDDO.

    " Xử lý phần thập phân: bỏ số 0 thừa ở cuối, dùng dấu phẩy
    IF lv_dec_int <> 0.
      DATA(lv_dec_str) = |{ lv_dec_int WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
      REPLACE ALL OCCURRENCES OF REGEX '0+$' IN lv_dec_str WITH ''.
      IF lv_dec_str IS NOT INITIAL.
        lv_formatted = |{ lv_formatted },{ lv_dec_str }|.
      ENDIF.
    ENDIF.

    rv_formatted = lv_formatted.
  ENDMETHOD.




















  METHOD escape_xml.
    rv_result = iv_text.
    rv_result = replace( val = rv_result sub = '&' with = '&amp;' occ = 0 ).
    rv_result = replace( val = rv_result sub = '<' with = '&lt;' occ = 0 ).
    rv_result = replace( val = rv_result sub = '>' with = '&gt;' occ = 0 ).
    rv_result = replace( val = rv_result sub = `"` with = '&quot;' occ = 0 ).
    rv_result = replace( val = rv_result sub = `'` with = '&apos;' occ = 0 ).
  ENDMETHOD.

ENDCLASS.
