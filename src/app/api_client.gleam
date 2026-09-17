pub type Client {
  Client
}

pub type UserId {
  UserId(Int)
}

pub type User {
  User(name: String)
}

pub type ApiError {
  UserNotFound
}

pub fn fetch_user(_client: Client, _id: UserId) -> Result(User, ApiError) {
  Ok(User(name: "Lucy"))
}

pub fn fetch_user_with_timeout(
  client: Client,
  id: UserId,
  timeout _timeout: Int,
) -> Result(User, ApiError) {
  fetch_user(client, id)
}
