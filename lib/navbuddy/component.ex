defmodule NavBuddy.Component do
  @moduledoc """
  LiveView components for NavBuddy navigation.

  This module provides LiveView components for rendering advanced navigation
  menus with support for dropdowns, mega menus, and mobile-responsive design.

  ## Components

  - `nav_menu/1` - Main navigation component
  - `nav_item/1` - Individual navigation item
  - `dropdown_menu/1` - Dropdown menu component
  - `mega_menu/1` - Mega menu component
  - `mobile_nav_toggle/1` - Mobile navigation toggle button

  ## Usage

      <.nav_menu
        items={@navigation_items}
        config={@nav_config}
        current_path={@current_path}
        id="main-nav"
      />

  ## Events

  The components emit the following Phoenix LiveView events:

  - `navbuddy:item_click` - When a navigation item is clicked
  - `navbuddy:dropdown_open` - When a dropdown is opened
  - `navbuddy:dropdown_close` - When a dropdown is closed
  - `navbuddy:mobile_toggle` - When mobile menu is toggled
  - `navbuddy:breadcrumb_click` - When a breadcrumb item is clicked

  ## Accessibility

  All components include comprehensive accessibility features:
  - ARIA labels and roles
  - Keyboard navigation support
  - Screen reader compatibility
  - Focus management
  """

  use Phoenix.Component
  import Phoenix.HTML.Form

  alias NavBuddy.Config
  alias Phoenix.LiveView.JS

  @doc """
  Renders the main navigation menu.

  ## Attributes

  - `items` (required) - List of navigation items
  - `config` - NavBuddy.Config struct (defaults to default config)
  - `current_path` - Current path for active state highlighting
  - `id` - HTML id attribute (defaults to "navbuddy-nav")
  - `class` - Additional CSS classes
  - `rest` - Additional HTML attributes

  ## Examples

      <.nav_menu items={@navigation_items} />

      <.nav_menu
        items={@navigation_items}
        config={%NavBuddy.Config{orientation: :vertical}}
        current_path={@current_path}
        id="main-navigation"
        class="my-custom-nav"
      />
  """
  attr :items, :list, required: true
  attr :config, NavBuddy.Config, default: %NavBuddy.Config{}
  attr :current_path, :string, default: nil
  attr :id, :string, default: "navbuddy-nav"
  attr :class, :string, default: ""
  attr :rest, :global

  def nav_menu(assigns) do
    assigns = assign_nav_data(assigns)

    ~H"""
    <nav
      id={@id}
      class={["navbuddy-nav", @class]}
      role="navigation"
      aria-label="Main navigation"
      {Map.merge(@data_attributes, @rest)}
    >
      <div class="navbuddy-nav-container">
        <!-- Mobile toggle button -->
        <.mobile_nav_toggle id={"#{@id}-toggle"} />

        <!-- Navigation items -->
        <div class="navbuddy-nav-content" id={"#{@id}-content"}>
          <ul class="navbuddy-nav-list" role="menubar">
            <li
              :for={{item, index} <- Enum.with_index(@processed_items)}
              class="navbuddy-nav-item"
              role="none"
            >
              <.nav_item
                item={item}
                config={@config}
                nav_id={@id}
                index={index}
                current_path={@current_path}
              />
            </li>
          </ul>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Renders an individual navigation item.

  Supports simple links, dropdown menus, and mega menus.
  """
  attr :item, :map, required: true
  attr :config, NavBuddy.Config, required: true
  attr :nav_id, :string, required: true
  attr :index, :integer, required: true
  attr :current_path, :string, default: nil
  attr :level, :integer, default: 1

  def nav_item(assigns) do
    assigns = assign_item_data(assigns)

    ~H"""
    <div class={@item_classes} {@item_attributes}>
      <%= cond do %>
        <% @item.mega_menu -> %>
          <.mega_menu_trigger item={@item} config={@config} nav_id={@nav_id} />
          <.mega_menu
            menu={@item.mega_menu}
            config={@config}
            nav_id={@nav_id}
            item_id={@item.id}
          />
        
        <% @item.dropdown -> %>
          <.dropdown_trigger item={@item} config={@config} nav_id={@nav_id} />
          <.dropdown_menu
            items={@item.dropdown}
            config={@config}
            nav_id={@nav_id}
            parent_id={@item.id}
            level={@level + 1}
            current_path={@current_path}
          />
        
        <% true -> %>
          <.nav_link item={@item} config={@config} />
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a navigation link.
  """
  attr :item, :map, required: true
  attr :config, NavBuddy.Config, required: true

  def nav_link(assigns) do
    ~H"""
    <%= if @item.href do %>
      <a
        href={@item.href}
        class={["navbuddy-nav-link", if(@item.active, do: "active"), if(@item.disabled, do: "disabled")]}
        role="menuitem"
        tabindex={if @item.disabled, do: "-1", else: "0"}
        aria-disabled={to_string(!!@item.disabled)}
        phx-click={JS.push("navbuddy:item_click", value: %{id: @item.id, href: @item.href})}
      >
        <.nav_icon :if={@item.icon} icon={@item.icon} />
        <span class="navbuddy-nav-text">{@item.label}</span>
      </a>
    <% else %>
      <span
        class={["navbuddy-nav-link", "no-href", if(@item.disabled, do: "disabled")]}
        role="menuitem"
        tabindex={if @item.disabled, do: "-1", else: "0"}
        aria-disabled={to_string(!!@item.disabled)}
      >
        <.nav_icon :if={@item.icon} icon={@item.icon} />
        <span class="navbuddy-nav-text">{@item.label}</span>
      </span>
    <% end %>
    """
  end

  @doc """
  Renders a dropdown trigger button.
  """
  attr :item, :map, required: true
  attr :config, NavBuddy.Config, required: true
  attr :nav_id, :string, required: true

  def dropdown_trigger(assigns) do
    assigns = assign(assigns, :menu_id, NavBuddy.generate_menu_id(assigns.nav_id, assigns.item.id))

    ~H"""
    <button
      class={["navbuddy-dropdown-trigger", if(@item.active, do: "active"), if(@item.disabled, do: "disabled")]}
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded="false"
      aria-controls={@menu_id}
      tabindex={if @item.disabled, do: "-1", else: "0"}
      aria-disabled={to_string(!!@item.disabled)}
      phx-click={
        if @config.dropdown_trigger == :click,
          do: JS.push("navbuddy:dropdown_toggle", value: %{id: @item.id, menu_id: @menu_id})
      }
      data-dropdown-trigger={@config.dropdown_trigger}
    >
      <.nav_icon :if={@item.icon} icon={@item.icon} />
      <span class="navbuddy-nav-text">{@item.label}</span>
      <.nav_icon icon="chevron-down" class="navbuddy-dropdown-icon" />
    </button>
    """
  end

  @doc """
  Renders a mega menu trigger button.
  """
  attr :item, :map, required: true
  attr :config, NavBuddy.Config, required: true
  attr :nav_id, :string, required: true

  def mega_menu_trigger(assigns) do
    assigns = assign(assigns, :menu_id, NavBuddy.generate_menu_id(assigns.nav_id, assigns.item.id))

    ~H"""
    <button
      class={["navbuddy-mega-trigger", if(@item.active, do: "active"), if(@item.disabled, do: "disabled")]}
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded="false"
      aria-controls={@menu_id}
      tabindex={if @item.disabled, do: "-1", else: "0"}
      aria-disabled={to_string(!!@item.disabled)}
      phx-click={
        if @config.dropdown_trigger == :click,
          do: JS.push("navbuddy:mega_menu_toggle", value: %{id: @item.id, menu_id: @menu_id})
      }
      data-dropdown-trigger={@config.dropdown_trigger}
    >
      <.nav_icon :if={@item.icon} icon={@item.icon} />
      <span class="navbuddy-nav-text">{@item.label}</span>
      <.nav_icon icon="chevron-down" class="navbuddy-dropdown-icon" />
    </button>
    """
  end

  @doc """
  Renders a dropdown menu.
  """
  attr :items, :list, required: true
  attr :config, NavBuddy.Config, required: true
  attr :nav_id, :string, required: true
  attr :parent_id, :string, required: true
  attr :level, :integer, default: 2
  attr :current_path, :string, default: nil

  def dropdown_menu(assigns) do
    assigns = assign(assigns, :menu_id, NavBuddy.generate_menu_id(assigns.nav_id, assigns.parent_id))

    ~H"""
    <div
      id={@menu_id}
      class={["navbuddy-dropdown", "navbuddy-dropdown-level-#{@level}"]}
      role="menu"
      aria-labelledby={"#{@nav_id}-#{@parent_id}-trigger"}
      data-level={@level}
    >
      <ul class="navbuddy-dropdown-list">
        <li
          :for={{item, index} <- Enum.with_index(@items)}
          class="navbuddy-dropdown-item"
          role="none"
        >
          <.nav_item
            item={item}
            config={@config}
            nav_id={@nav_id}
            index={index}
            level={@level}
            current_path={@current_path}
          />
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a mega menu.
  """
  attr :menu, :map, required: true
  attr :config, NavBuddy.Config, required: true
  attr :nav_id, :string, required: true
  attr :item_id, :string, required: true

  def mega_menu(assigns) do
    assigns = assign(assigns, :menu_id, NavBuddy.generate_menu_id(assigns.nav_id, assigns.item_id))

    ~H"""
    <div
      id={@menu_id}
      class="navbuddy-mega-menu"
      role="menu"
      aria-labelledby={"#{@nav_id}-#{@item_id}-trigger"}
    >
      <div class="navbuddy-mega-menu-container">
        <div class="navbuddy-mega-menu-header">
          <h3 class="navbuddy-mega-menu-title">{@menu.title}</h3>
          <p :if={@menu.description} class="navbuddy-mega-menu-description">
            {@menu.description}
          </p>
        </div>

        <div class="navbuddy-mega-menu-grid">
          <div
            :for={section <- @menu.sections}
            class="navbuddy-mega-menu-section"
            role="group"
            aria-labelledby={"#{@menu_id}-section-#{section.title |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "-")}"}
          >
            <h4
              id={"#{@menu_id}-section-#{section.title |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "-")}"}
              class="navbuddy-mega-menu-section-title"
            >
              {section.title}
            </h4>
            <p :if={section.description} class="navbuddy-mega-menu-section-description">
              {section.description}
            </p>

            <ul class="navbuddy-mega-menu-section-items">
              <li :for={item <- section.items} class="navbuddy-mega-menu-item" role="none">
                <.nav_link item={item} config={@config} />
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the mobile navigation toggle button.
  """
  attr :id, :string, required: true
  attr :class, :string, default: ""

  def mobile_nav_toggle(assigns) do
    ~H"""
    <button
      id={@id}
      class={["navbuddy-mobile-toggle", @class]}
      type="button"
      aria-label="Toggle navigation menu"
      aria-expanded="false"
      aria-controls="navbuddy-nav-content"
      phx-click={JS.push("navbuddy:mobile_toggle")}
    >
      <span class="navbuddy-mobile-toggle-icon">
        <span class="navbuddy-mobile-toggle-line"></span>
        <span class="navbuddy-mobile-toggle-line"></span>
        <span class="navbuddy-mobile-toggle-line"></span>
      </span>
      <span class="navbuddy-mobile-toggle-text">Menu</span>
    </button>
    """
  end

  @doc """
  Renders navigation breadcrumbs.
  """
  attr :items, :list, required: true
  attr :current_path, :string, required: true
  attr :config, NavBuddy.Config, default: %NavBuddy.Config{}
  attr :id, :string, default: "navbuddy-breadcrumbs"
  attr :class, :string, default: ""

  def nav_breadcrumbs(assigns) do
    assigns = assign(assigns, :breadcrumbs, NavBuddy.generate_breadcrumbs(assigns.items, assigns.current_path))

    ~H"""
    <nav
      :if={length(@breadcrumbs) > 1}
      id={@id}
      class={["navbuddy-breadcrumbs", @class]}
      role="navigation"
      aria-label="Breadcrumb navigation"
    >
      <ol class="navbuddy-breadcrumbs-list">
        <li
          :for={{crumb, index} <- Enum.with_index(@breadcrumbs)}
          class="navbuddy-breadcrumbs-item"
        >
          <%= if index < length(@breadcrumbs) - 1 do %>
            <a
              href={crumb.href}
              class="navbuddy-breadcrumbs-link"
              phx-click={JS.push("navbuddy:breadcrumb_click", value: %{id: crumb.id, href: crumb.href})}
            >
              {crumb.label}
            </a>
            <.nav_icon icon="chevron-right" class="navbuddy-breadcrumbs-separator" />
          <% else %>
            <span class="navbuddy-breadcrumbs-current" aria-current="page">
              {crumb.label}
            </span>
          <% end %>
        </li>
      </ol>
    </nav>
    """
  end

  @doc """
  Renders a navigation icon.
  """
  attr :icon, :string, required: true
  attr :class, :string, default: ""
  attr :rest, :global

  def nav_icon(assigns) do
    ~H"""
    <svg
      class={["navbuddy-icon", "navbuddy-icon-#{@icon}", @class]}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      {@rest}
    >
      <%= case @icon do %>
        <% "home" -> %>
          <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
          <polyline points="9,22 9,12 15,12 15,22"/>
        <% "package" -> %>
          <line x1="16.5" y1="9.4" x2="7.5" y2="4.21"/>
          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
          <polyline points="3.27,6.96 12,12.01 20.73,6.96"/>
          <line x1="12" y1="22.08" x2="12" y2="12"/>
        <% "globe" -> %>
          <circle cx="12" cy="12" r="10"/>
          <line x1="2" y1="12" x2="22" y2="12"/>
          <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
        <% "smartphone" -> %>
          <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
          <line x1="12" y1="18" x2="12.01" y2="18"/>
        <% "monitor" -> %>
          <rect x="2" y="3" width="20" height="14" rx="2" ry="2"/>
          <line x1="8" y1="21" x2="16" y2="21"/>
          <line x1="12" y1="17" x2="12" y2="21"/>
        <% "settings" -> %>
          <circle cx="12" cy="12" r="3"/>
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1 1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
        <% "code" -> %>
          <polyline points="16,18 22,12 16,6"/>
          <polyline points="8,6 2,12 8,18"/>
        <% "palette" -> %>
          <circle cx="13.5" cy="6.5" r=".5"/>
          <circle cx="17.5" cy="10.5" r=".5"/>
          <circle cx="8.5" cy="7.5" r=".5"/>
          <circle cx="6.5" cy="12.5" r=".5"/>
          <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>
        <% "users" -> %>
          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
          <circle cx="9" cy="7" r="4"/>
          <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        <% "layers" -> %>
          <polygon points="12,2 2,7 12,12 22,7 12,2"/>
          <polyline points="2,17 12,22 22,17"/>
          <polyline points="2,12 12,17 22,12"/>
        <% "zap" -> %>
          <polygon points="13,2 3,14 12,14 11,22 21,10 12,10 13,2"/>
        <% "trending-up" -> %>
          <polyline points="23,6 13.5,15.5 8.5,10.5 1,18"/>
          <polyline points="17,6 23,6 23,12"/>
        <% "star" -> %>
          <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26 12,2"/>
        <% "building" -> %>
          <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>
          <path d="M6 12H4a2 2 0 0 0-2 2v8h20v-8a2 2 0 0 0-2-2h-2"/>
          <path d="M18 9h2a2 2 0 0 1 2 2v1"/>
          <path d="M18 22V10"/>
          <path d="M6 10v12"/>
          <path d="m10 7 2 2 2-2"/>
        <% "tool" -> %>
          <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>
        <% "headphones" -> %>
          <path d="M3 18v-6a9 9 0 0 1 18 0v6"/>
          <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/>
        <% "heart" -> %>
          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
        <% "dollar-sign" -> %>
          <line x1="12" y1="1" x2="12" y2="23"/>
          <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
        <% "book" -> %>
          <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
          <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
        <% "info" -> %>
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="16" x2="12" y2="12"/>
          <line x1="12" y1="8" x2="12.01" y2="8"/>
        <% "mail" -> %>
          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
          <polyline points="22,6 12,13 2,6"/>
        <% "chevron-down" -> %>
          <polyline points="6,9 12,15 18,9"/>
        <% "chevron-right" -> %>
          <polyline points="9,18 15,12 9,6"/>
        <% _ -> %>
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="8" x2="12" y2="16"/>
          <line x1="8" y1="12" x2="16" y2="12"/>
      <% end %>
    </svg>
    """
  end

  # Private helper functions

  defp assign_nav_data(assigns) do
    processed_items = NavBuddy.find_active_item(assigns.items, assigns.current_path || "")
    data_attributes = Config.to_data_attributes(assigns.config)

    assigns
    |> assign(:processed_items, processed_items)
    |> assign(:data_attributes, data_attributes)
  end

  defp assign_item_data(assigns) do
    item_classes = [
      "navbuddy-nav-item-wrapper",
      if(assigns.item.active, do: "active"),
      if(assigns.item.disabled, do: "disabled"),
      if(assigns.item.dropdown, do: "has-dropdown"),
      if(assigns.item.mega_menu, do: "has-mega-menu")
    ]

    item_attributes = %{
      "data-item-id" => assigns.item.id,
      "data-level" => assigns.level
    }

    assigns
    |> assign(:item_classes, item_classes)
    |> assign(:item_attributes, item_attributes)
  end
end