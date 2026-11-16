param($Name,$Json)
$h=@{Accept='application/json, text/event-stream'}
$u='https://mcp.kiwi.com'
$r=Invoke-WebRequest -Uri $u -Method Post -Headers $h -ContentType 'application/json' -Body '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' -UseBasicParsing
$sid=$r.Headers['Mcp-Session-Id']; if($sid){$h['Mcp-Session-Id']=[string]$sid}
Invoke-WebRequest -Uri $u -Method Post -Headers $h -ContentType 'application/json' -Body '{"jsonrpc":"2.0","method":"notifications/initialized"}' -UseBasicParsing | Out-Null
$body=@{jsonrpc='2.0';id=3;method='tools/call';params=@{name='search-flight';arguments=($Json|ConvertFrom-Json)}}|ConvertTo-Json -Depth 8
$x=Invoke-WebRequest -Uri $u -Method Post -Headers $h -ContentType 'application/json' -Body $body -UseBasicParsing -TimeoutSec 110
$line=($x.Content -split "`n"|?{$_ -like 'data:*'}|select -First 1).Substring(5)
$o=$line|ConvertFrom-Json
$sc=$o.result.structuredContent
if(-not $sc){$o|ConvertTo-Json -Depth 5; return}
$sc|ConvertTo-Json -Depth 12|Out-File "$env:TEMP\kiwi_$Name.json" -Encoding utf8
"$Name count=$($sc.resultsCount) err=$($sc.error)"
$sc.itineraries|select -First 12|%{ "{0} | {1} | out {2} {3}->{4} stops{5} | in {6} {7}->{8} stops{9} | bag {10}/{11}/{12} | {13}" -f $_.priceFormatted,($_.outbound.segments|%{$_.carrier}|select -Unique) -join '+',($_.outbound.route -join '>'),$_.outbound.departureTime,$_.outbound.arrivalTime,$_.outbound.stops,($_.inbound.route -join '>'),$_.inbound.departureTime,$_.inbound.arrivalTime,$_.inbound.stops,$_.baggage.personalItem,$_.baggage.cabinBag,$_.baggage.checkedBag,$_.bookingUrl }
