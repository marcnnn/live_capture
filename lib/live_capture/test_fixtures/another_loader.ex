# Test fixture: A separate loader module to test that Component.list/1
# correctly filters components by their loader.
defmodule LiveCapture.TestFixtures.AnotherLoader do
  @moduledoc false
  use LiveCapture.Component

  breakpoints s: "320px", m: "640px"
end
