
{constants} = require '../constants'
{v_codes} = constants
pkg = require '../../package.json'

#==============================================================

class BaseScraper
  constructor : ({@libs, log_level, @proxy, @ca}) ->
    @log_level = log_level or "debug"

  hunt : (username, proof_check_text, cb) -> hunt2 { username, proof_check_text }, cb
  hunt2 : (args, cb) -> cb new Error "unimplemented"
  id_to_url : (username, status_id) ->
  check_status : ({username, url, signature, status_id}, cb) -> 
  _check_args : () -> new Error "unimplemented"

  #-------------------------------------------------------------

  logl : (level, msg) ->
    if (k = @libs.log)? then k[level](msg)

  #-------------------------------------------------------------

  log : (msg) ->
    if (k = @libs.log)? and @log_level? then k[@log_level](msg)

  #-------------------------------------------------------------

  validate : (args, cb) ->
    err = null
    rc = null
    if (err = @_check_args(args)) then # noop
    else if not @_check_api_url args
      err = new Error "check url failed for #{JSON.stringify args}"
    else
      err = @_validate_text_check args
    unless err?
      await @check_status args, defer err, rc
    cb err, rc

  #-------------------------------------------------------------

  # Convert away from MS-dos style encoding...
  _stripr : (m) -> m.split('\r').join('')

  #-------------------------------------------------------------

  _get_url_body: (opts, cb) ->
    ###
      cb(err, body) only replies with body if status is 200
    ###
    body = null
    opts.proxy = @proxy if @proxy?
    opts.ca = @ca if @ca?
    opts.timeout = constants.http_timeout unless opts.timeout?
    opts.headers or= {}
    opts.headers["User-Agent"] = constants.user_agent + " v" + pkg.version
    await @libs.request opts, defer err, response, body
    rc = if err? 
      if err.code is 'ETIMEDOUT' then               v_codes.TIMEOUT
      else                                          v_codes.HOST_UNREACHABLE
    else if (response.statusCode in [401,403]) then v_codes.PERMISSION_DENIED
    else if (response.statusCode is 200)       then v_codes.OK
    else if (response.statusCode >= 500)       then v_codes.HTTP_500
    else if (response.statusCode >= 400)       then v_codes.HTTP_400
    else if (response.statusCode >= 300)       then v_codes.HTTP_300
    else                                            v_codes.HTTP_OTHER
    cb err, rc, body

  #--------------------------------------------------------------

#==============================================================

exports.BaseScraper = BaseScraper

#==============================================================

