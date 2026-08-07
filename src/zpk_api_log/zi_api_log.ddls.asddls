@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'zi_api_Log'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zi_api_Log
  as select from ztb_api_log
{
  key log_uuid    as LogUuid,
  key api_type    as ApiType,
      http_method as HttpMethod,
      uri         as Uri,
      auth_type   as AuthType,
      params      as Params,
      headers     as Headers,
      body        as Body,
      response    as Response,
      status_code as StatusCode,
      created_by  as CreatedBy,
      created_at  as CreatedAt
}
