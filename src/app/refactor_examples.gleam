import app/api_client
import app/mailer
import app/subscription

pub type App {
  App(
    client: api_client.Client,
    database: subscription.Database,
    mailer: mailer.Mailer,
  )
}

pub type Request {
  Request(user_id: api_client.UserId)
}

pub type Account {
  Account(id: subscription.UserId)
}

pub type Recipient {
  Recipient(email: String, name: String)
}

pub fn load_user(
  app: App,
  request: Request,
) -> Result(api_client.User, api_client.ApiError) {
  api_client.fetch_user(app.client, request.user_id)
}

pub fn activate_subscription(
  app: App,
  account: Account,
) -> Result(Nil, subscription.DatabaseError) {
  subscription.update(app.database, account.id, True)
}

pub fn send_welcome_email(
  app: App,
  recipient: Recipient,
) -> Result(Nil, mailer.MailError) {
  mailer.send(
    app.mailer,
    recipient.email,
    welcome_subject(recipient),
    render_body(recipient),
  )
}

fn welcome_subject(recipient: Recipient) -> String {
  "Welcome, " <> recipient.name
}

fn render_body(recipient: Recipient) -> String {
  "Hello " <> recipient.name <> ", your account is ready."
}
