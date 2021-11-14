$headers = @{
}

$params = @{
    Uri         = 'http://127.0.0.1:4048/summary'
    Headers     = $headers
    Method      = 'GET'
#    ContentType = 'application/json'
}

Invoke-RestMethod @params
