You will need your azure speech key which is nothing but your cogSvcSubKey which will used in the config file.

Call this URL using postman or curl. Here I am using a dummy key for demo purpose

curl --location 'https://westus2.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1' \
--header 'Ocp-Apim-Subscription-Key: 3456b27223r52f57448097253rd6ca51'

Your response will be like this

{
    "Urls": [
        "turn:relay.communication.microsoft.com:3478"
    ],
    "Username": "......",
    "Password": "......"
}

That’s it you got your iceUrl, iceUsername and icePassword. Keep it somewhere because we will need it in the config file.