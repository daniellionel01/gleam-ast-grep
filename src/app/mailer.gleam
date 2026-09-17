pub type Mailer {
  Mailer
}

pub type MailError {
  DeliveryFailed
}

pub type Message {
  Message(to: String, subject: String, body: String)
}

pub fn send(
  _sender: Mailer,
  _address: String,
  _subject: String,
  _body: String,
) -> Result(Nil, MailError) {
  Ok(Nil)
}

pub fn send_message(
  _sender: Mailer,
  _message: Message,
) -> Result(Nil, MailError) {
  Ok(Nil)
}
