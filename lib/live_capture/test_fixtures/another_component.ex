# Test fixture: A component that uses AnotherLoader instead of LiveCaptureDemo.
# This is used to test that Component.list/1 correctly filters by loader.
defmodule LiveCapture.TestFixtures.AnotherComponent do
  @moduledoc false
  use Phoenix.Component
  use LiveCapture.TestFixtures.AnotherLoader

  capture_all()

  def another_simple(assigns) do
    ~H"""
    <p>Another simple component</p>
    """
  end
end
