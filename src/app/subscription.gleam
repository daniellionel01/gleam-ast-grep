pub type Database {
  Database
}

pub type UserId {
  UserId(Int)
}

pub type DatabaseError {
  UpdateFailed
}

pub type Status {
  Active
  Suspended
}

pub fn update(
  _db: Database,
  _user_id: UserId,
  _active: Bool,
) -> Result(Nil, DatabaseError) {
  Ok(Nil)
}

pub fn set_status(
  _db: Database,
  _user_id: UserId,
  _status: Status,
) -> Result(Nil, DatabaseError) {
  Ok(Nil)
}
