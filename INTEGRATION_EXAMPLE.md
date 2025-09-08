# NavBuddy Integration Example

This example shows how to integrate NavBuddy into a Phoenix LiveView application.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:navbuddy, "~> 0.1.0"}
  ]
end
```

## Configuration

In your application layout template, include the CSS and JavaScript:

```html
<!-- In your app.html.heex -->
<link rel="stylesheet" href="/assets/navbuddy.css" />
<script src="/assets/navbuddy.js"></script>
```

## Usage in LiveView

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  import NavBuddy.Component
  import NavBuddy.LiveHelpers

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_navbuddy_state()
      |> assign(:navigation_items, navigation_items())
      |> assign(:current_path, "/")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.nav_menu
        items={@navigation_items}
        config={NavBuddy.default_config()}
        current_path={@current_path}
      />

      <main>
        <!-- Your page content -->
      </main>
    </div>
    """
  end

  defp navigation_items do
    [
      %{id: "home", label: "Home", href: "/"},
      %{id: "about", label: "About", href: "/about"},
      %{
        id: "products",
        label: "Products",
        href: "/products",
        dropdown: [
          %{id: "web", label: "Web Apps", href: "/products/web"},
          %{id: "mobile", label: "Mobile Apps", href: "/products/mobile"}
        ]
      },
      %{id: "contact", label: "Contact", href: "/contact"}
    ]
  end

  # NavBuddy event handlers are automatically available when you import NavBuddy.LiveHelpers
end
```

## Custom Configuration

```elixir
def mount(_params, _session, socket) do
  custom_config = %NavBuddy.Config{
    orientation: :vertical,
    theme: :dark,
    dropdown_trigger: :click,
    mobile_behavior: :overlay,
    animations: true
  }

  socket =
    socket
    |> assign_navbuddy_state(config: custom_config)
    |> assign(:navigation_items, navigation_items())

  {:ok, socket}
end
```
