defmodule WttjWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import WttjWeb.ChannelCase

      @endpoint WttjWeb.Endpoint
    end
  end

  setup tags do
    Wttj.DataCase.setup_sandbox(tags)
    :ok
  end
end
