### PHP FCM sender

Endpoints
- POST `send_push.php`

Request JSON
```json
{
  "token": "DEVICE_TOKEN_OR_TOPIC_NAME",
  "title": "Hello",
  "body": "World",
  "data": {"foo": "bar"},
  "isTopic": false
}
```

Setup
- Copy `.env.example` to `.env` and fill `FCM_SERVER_KEY` (Project Settings → Cloud Messaging → Legacy server key)
- Serve with: `php -S 0.0.0.0:8080 -t backend`

