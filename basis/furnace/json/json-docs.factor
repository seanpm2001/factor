USING: furnace.json help.markup help.syntax http http.server
kernel vocabs.loader ;
IN: furnace.json+docs

HELP: <json-content>
{ $values { "body" object } { "response" response } }
{ $description "Creates an HTTP response which serves a serialized JSON object to the client." } ;

ARTICLE: "furnace.json" "Furnace JSON support"
"The " { $vocab-link "furnace.json" } " vocabulary provides a utility word for serving HTTP responses with JSON content."
{ $subsections <json-content> } ;

ABOUT: "furnace.json"
