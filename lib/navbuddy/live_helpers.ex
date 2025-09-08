defmodule NavBuddy.LiveHelpers do
  @moduledoc """
  LiveView helpers for NavBuddy navigation components.

  This module provides helper functions for handling NavBuddy events and
  managing navigation state in Phoenix LiveView applications.

  ## Usage

  Include this module in your LiveView to get access to NavBuddy event handlers:

      defmodule MyAppWeb.PageLive do
        use MyAppWeb, :live_view
        import NavBuddy.LiveHelpers

        def mount(_params, _session, socket) do
          socket =
            socket
            |> assign_navbuddy_state()
            |> assign(:navigation_items, MyApp.Navigation.items())

          {:ok, socket}
        end

        # NavBuddy event handlers are automatically available
      end

  ## Event Handling

  The following events are handled automatically when you import this module:

  - `navbuddy:item_click` - Navigation item clicked
  - `navbuddy:dropdown_toggle` - Dropdown menu toggled
  - `navbuddy:mega_menu_toggle` - Mega menu toggled
  - `navbuddy:mobile_toggle` - Mobile menu toggled
  - `navbuddy:breadcrumb_click` - Breadcrumb item clicked

  ## State Management

  NavBuddy maintains the following state in your LiveView assigns:

  - `:navbuddy_mobile_open` - Boolean indicating if mobile menu is open
  - `:navbuddy_active_dropdown` - ID of currently active dropdown
  - `:navbuddy_active_mega_menu` - ID of currently active mega menu
  - `:navbuddy_config` - Current NavBuddy configuration

  ## Custom Event Handling

  You can override the default event handlers by defining your own:

      def handle_event("navbuddy:item_click", %{"id" => id, "navigate" => navigate}, socket) do
        # Custom logic here
        MyApp.Analytics.track_navigation(id)
        {:noreply, push_navigate(socket, to: navigate)}
      end
  """

  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias NavBuddy.Config

  @doc """
  Assigns initial NavBuddy state to the socket.

  ## Options

  - `:config` - NavBuddy.Config struct (defaults to default config)
  - `:mobile_open` - Initial mobile menu state (defaults to false)

  ## Examples

      socket = assign_navbuddy_state(socket)

      socket = assign_navbuddy_state(socket,
        config: %NavBuddy.Config{theme: :dark},
        mobile_open: false
      )
  """
  def assign_navbuddy_state(socket, opts \\ []) do
    config = Keyword.get(opts, :config, NavBuddy.default_config())
    mobile_open = Keyword.get(opts, :mobile_open, false)

    socket
    |> assign(:navbuddy_mobile_open, mobile_open)
    |> assign(:navbuddy_active_dropdown, nil)
    |> assign(:navbuddy_active_mega_menu, nil)
    |> assign(:navbuddy_config, config)
  end

  @doc """
  Updates the NavBuddy configuration.

  ## Examples

      socket = update_navbuddy_config(socket, %NavBuddy.Config{theme: :dark})

      socket = update_navbuddy_config(socket, fn config ->
        %{config | orientation: :vertical}
      end)
  """
  def update_navbuddy_config(socket, %Config{} = config) do
    assign(socket, :navbuddy_config, config)
  end

  def update_navbuddy_config(socket, update_fn) when is_function(update_fn, 1) do
    current_config = socket.assigns[:navbuddy_config] || NavBuddy.default_config()
    new_config = update_fn.(current_config)
    assign(socket, :navbuddy_config, new_config)
  end

  @doc """
  Toggles the mobile navigation menu.

  ## Examples

      socket = toggle_mobile_nav(socket)

      socket = toggle_mobile_nav(socket, true)  # Force open
      socket = toggle_mobile_nav(socket, false) # Force close
  """
  def toggle_mobile_nav(socket, force_state \\ nil) do
    current_state = socket.assigns[:navbuddy_mobile_open] || false

    new_state =
      case force_state do
        nil -> !current_state
        state when is_boolean(state) -> state
      end

    socket
    |> assign(:navbuddy_mobile_open, new_state)
    |> push_event("navbuddy:mobile_state_changed", %{open: new_state})
  end

  @doc """
  Sets the active dropdown menu.

  ## Examples

      socket = set_active_dropdown(socket, "products")
      socket = set_active_dropdown(socket, nil)  # Close all dropdowns
  """
  def set_active_dropdown(socket, dropdown_id) do
    socket
    |> assign(:navbuddy_active_dropdown, dropdown_id)
    # Close mega menu when dropdown opens
    |> assign(:navbuddy_active_mega_menu, nil)
    |> push_event("navbuddy:dropdown_state_changed", %{
      active_dropdown: dropdown_id,
      active_mega_menu: nil
    })
  end

  @doc """
  Sets the active mega menu.

  ## Examples

      socket = set_active_mega_menu(socket, "solutions")
      socket = set_active_mega_menu(socket, nil)  # Close all mega menus
  """
  def set_active_mega_menu(socket, mega_menu_id) do
    socket
    |> assign(:navbuddy_active_mega_menu, mega_menu_id)
    # Close dropdown when mega menu opens
    |> assign(:navbuddy_active_dropdown, nil)
    |> push_event("navbuddy:mega_menu_state_changed", %{
      active_dropdown: nil,
      active_mega_menu: mega_menu_id
    })
  end

  @doc """
  Closes all open menus (dropdowns and mega menus).

  ## Examples

      socket = close_all_menus(socket)
  """
  def close_all_menus(socket) do
    socket
    |> assign(:navbuddy_active_dropdown, nil)
    |> assign(:navbuddy_active_mega_menu, nil)
    |> push_event("navbuddy:all_menus_closed", %{})
  end

  @doc """
  Tracks a navigation analytics event.

  ## Examples

      socket = track_nav_event(socket, :item_click, %{id: "home", navigate: "/"})
      socket = track_nav_event(socket, :dropdown_open, %{id: "products"})
  """
  def track_nav_event(socket, event_type, data \\ %{}) do
    config = socket.assigns[:navbuddy_config] || NavBuddy.default_config()

    if config.analytics do
      push_event(socket, "navbuddy:analytics", %{
        event: event_type,
        data: data,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      })
    else
      socket
    end
  end

  @doc """
  Generates a unique navigation session ID for analytics.

  ## Examples

      session_id = generate_nav_session_id()
  """
  def generate_nav_session_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode64(padding: false)
    |> String.replace(~r/[^a-zA-Z0-9]/, "")
    |> String.slice(0, 16)
  end

  # Default event handlers that can be overridden

  defmacro __using__(_opts) do
    quote do
      import NavBuddy.LiveHelpers

      # Navigation item click handler
      def handle_event("navbuddy:item_click", %{"id" => id} = params, socket) do
        socket = track_nav_event(socket, :item_click, params)

        case Map.get(params, "navigate") do
          nil ->
            {:noreply, socket}

          navigate ->
            {:noreply, push_navigate(socket, to: navigate)}
        end
      end

      # Dropdown toggle handler
      def handle_event("navbuddy:dropdown_toggle", %{"id" => id}, socket) do
        current_dropdown = socket.assigns[:navbuddy_active_dropdown]

        new_dropdown =
          if current_dropdown == id do
            nil
          else
            id
          end

        socket =
          socket
          |> set_active_dropdown(new_dropdown)
          |> track_nav_event(:dropdown_toggle, %{
            id: id,
            state: if(new_dropdown, do: "open", else: "close")
          })

        {:noreply, socket}
      end

      # Mega menu toggle handler
      def handle_event("navbuddy:mega_menu_toggle", %{"id" => id}, socket) do
        current_mega_menu = socket.assigns[:navbuddy_active_mega_menu]

        new_mega_menu =
          if current_mega_menu == id do
            nil
          else
            id
          end

        socket =
          socket
          |> set_active_mega_menu(new_mega_menu)
          |> track_nav_event(:mega_menu_toggle, %{
            id: id,
            state: if(new_mega_menu, do: "open", else: "close")
          })

        {:noreply, socket}
      end

      # Mobile menu toggle handler
      def handle_event("navbuddy:mobile_toggle", _params, socket) do
        socket =
          socket
          |> toggle_mobile_nav()
          |> track_nav_event(:mobile_toggle, %{
            state: if(socket.assigns[:navbuddy_mobile_open], do: "open", else: "close")
          })

        {:noreply, socket}
      end

      # Breadcrumb click handler
      def handle_event("navbuddy:breadcrumb_click", %{"id" => id} = params, socket) do
        socket = track_nav_event(socket, :breadcrumb_click, params)

        case Map.get(params, "navigate") do
          nil ->
            {:noreply, socket}

          navigate ->
            {:noreply, push_navigate(socket, to: navigate)}
        end
      end

      # Menu close handler (triggered by JavaScript)
      def handle_event("navbuddy:close_menus", _params, socket) do
        {:noreply, close_all_menus(socket)}
      end

      # Orientation toggle handler
      def handle_event("navbuddy:toggle_orientation", _params, socket) do
        socket =
          update_navbuddy_config(socket, fn config ->
            new_orientation =
              if config.orientation == :horizontal, do: :vertical, else: :horizontal

            %{config | orientation: new_orientation}
          end)
          |> track_nav_event(:orientation_toggle, %{
            orientation: socket.assigns.navbuddy_config.orientation
          })

        {:noreply, socket}
      end

      # Theme toggle handler
      def handle_event("navbuddy:toggle_theme", _params, socket) do
        socket =
          update_navbuddy_config(socket, fn config ->
            new_theme =
              case config.theme do
                :light -> :dark
                :dark -> :auto
                :auto -> :light
              end

            %{config | theme: new_theme}
          end)
          |> track_nav_event(:theme_toggle, %{theme: socket.assigns.navbuddy_config.theme})

        {:noreply, socket}
      end

      # Allow overriding these handlers
      defoverridable handle_event: 3
    end
  end

  @doc """
  Helper for responsive navigation utilities.

  ## Examples

      # In your LiveView template
      <div class={responsive_nav_classes(@navbuddy_config, @navbuddy_mobile_open)}>
        <!-- Navigation content -->
      </div>
  """
  def responsive_nav_classes(config, mobile_open \\ false) do
    [
      "navbuddy-responsive",
      "navbuddy-#{config.orientation}",
      "navbuddy-theme-#{config.theme}",
      "navbuddy-trigger-#{config.dropdown_trigger}",
      "navbuddy-mobile-#{config.mobile_behavior}",
      if(mobile_open, do: "navbuddy-mobile-open", else: "navbuddy-mobile-closed"),
      if(config.animations,
        do: "navbuddy-animations-enabled",
        else: "navbuddy-animations-disabled"
      ),
      if(config.accessibility, do: "navbuddy-accessibility-enabled"),
      if(config.touch_gestures, do: "navbuddy-touch-enabled")
    ]
    |> Enum.filter(&(&1 != nil))
  end

  @doc """
  Helper for generating navigation analytics data.

  ## Examples

      analytics_data = nav_analytics_data(
        socket,
        :item_click,
        %{id: "products", navigate: "/products"}
      )
  """
  def nav_analytics_data(socket, event_type, event_data \\ %{}) do
    config = socket.assigns[:navbuddy_config] || NavBuddy.default_config()

    base_data = %{
      event: event_type,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      config: %{
        orientation: config.orientation,
        theme: config.theme,
        dropdown_trigger: config.dropdown_trigger,
        mobile_behavior: config.mobile_behavior
      },
      state: %{
        mobile_open: socket.assigns[:navbuddy_mobile_open] || false,
        active_dropdown: socket.assigns[:navbuddy_active_dropdown],
        active_mega_menu: socket.assigns[:navbuddy_active_mega_menu]
      }
    }

    Map.merge(base_data, %{data: event_data})
  end

  @doc """
  Helper for managing focus state in navigation menus.

  ## Examples

      socket = manage_nav_focus(socket, :dropdown_opened, "products-menu")
      socket = manage_nav_focus(socket, :mobile_menu_closed)
  """
  def manage_nav_focus(socket, focus_action, target \\ nil) do
    focus_data =
      case focus_action do
        :dropdown_opened ->
          %{action: "focus", target: target, type: "dropdown"}

        :mega_menu_opened ->
          %{action: "focus", target: target, type: "mega_menu"}

        :mobile_menu_opened ->
          %{action: "focus", target: "navbuddy-mobile-toggle", type: "mobile"}

        :mobile_menu_closed ->
          %{action: "focus", target: "navbuddy-mobile-toggle", type: "mobile"}

        :menu_closed ->
          %{action: "restore_focus", type: "general"}

        _ ->
          %{action: "no_change"}
      end

    push_event(socket, "navbuddy:focus_management", focus_data)
  end

  @doc """
  Helper for keyboard navigation handling.

  ## Examples

      socket = handle_nav_keyboard(socket, "ArrowDown", "products-dropdown")
  """
  def handle_nav_keyboard(socket, key, context) do
    keyboard_data = %{
      key: key,
      context: context,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    socket
    |> push_event("navbuddy:keyboard_navigation", keyboard_data)
    |> track_nav_event(:keyboard_navigation, keyboard_data)
  end
end
