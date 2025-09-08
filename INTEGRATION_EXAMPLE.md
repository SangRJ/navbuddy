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
      %{id: "home", label: "Home", navigate: "/"},
      %{id: "about", label: "About", navigate: "/about"},
      %{
        id: "products",
        label: "Products",
        navigate: "/products",
        dropdown: [
          %{id: "web", label: "Web Apps", navigate: "/products/web"},
          %{id: "mobile", label: "Mobile Apps", navigate: "/products/mobile"}
        ]
      },
      %{id: "contact", label: "Contact", navigate: "/contact"}
    ]
  end  # NavBuddy event handlers are automatically available when you import NavBuddy.LiveHelpers
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

## Permissions-Based Navigation

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import NavBuddy.Component
  import NavBuddy.LiveHelpers

  def mount(_params, session, socket) do
    current_user = get_current_user(session)
    user_permissions = get_user_permissions(current_user)

    socket =
      socket
      |> assign_navbuddy_state()
      |> assign(:navigation_items, protected_navigation_items())
      |> assign(:user_permissions, user_permissions)
      |> assign(:current_path, "/dashboard")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.nav_menu
        items={@navigation_items}
        user_permissions={@user_permissions}
        config={NavBuddy.default_config()}
        current_path={@current_path}
      />
      <!-- Your dashboard content -->
    </div>
    """
  end

  defp protected_navigation_items do
    [
      %{id: "dashboard", label: "Dashboard", navigate: "/dashboard"},
      %{id: "profile", label: "Profile", navigate: "/profile", permissions: "user"},
      %{
        id: "admin",
        label: "Administration",
        dropdown: [
          %{id: "users", label: "User Management", navigate: "/admin/users", permissions: "admin"},
          %{id: "settings", label: "System Settings", navigate: "/admin/settings", permissions: "admin"},
          %{id: "analytics", label: "Analytics", navigate: "/admin/analytics", permissions: ["admin", "analyst"]}
        ]
      },
      %{
        id: "reports",
        label: "Reports",
        mega_menu: %{
          "Basic" => [
            %{id: "sales", label: "Sales Report", navigate: "/reports/sales", permissions: "user"},
            %{id: "traffic", label: "Traffic Report", navigate: "/reports/traffic", permissions: "user"}
          ],
          "Advanced" => [
            %{id: "detailed", label: "Detailed Analytics", navigate: "/reports/detailed", permissions: ["admin", "analyst"]},
            %{id: "custom", label: "Custom Reports", navigate: "/reports/custom", permissions: "admin"}
          ]
        }
      }
    ]
  end

  defp get_current_user(session) do
    # Your user retrieval logic
    session["current_user"]
  end

  defp get_user_permissions(%{role: "admin"}), do: ["user", "admin"]
  defp get_user_permissions(%{role: "analyst"}), do: ["user", "analyst"]
  defp get_user_permissions(%{role: "user"}), do: ["user"]
  defp get_user_permissions(_), do: []
end
```
