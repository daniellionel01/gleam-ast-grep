const first = "wibble"

pub fn main() -> String {
  let name = first <> "wobble"
  echo name
}

pub fn stringly_typed_error() -> Result(Int, String) {
  Error("dummy error")
}

pub fn explicit_parameter_types(value) -> Int {
  value
}

pub fn boolean_blindness(enabled: Bool) -> Bool {
  enabled
}
