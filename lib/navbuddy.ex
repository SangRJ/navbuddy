defmodule NavBuddy do
  @moduledoc """
  NavBuddy - Advanced Configurable Navigation Component for Phoenix LiveView

  NavBuddy provides comprehensive navigation components for Phoenix LiveView applications,
  featuring dropdowns, mega menus, mobile-responsive design, and accessibility support.

  ## Basic Usage

      defmodule MyAppWeb.LayoutView do
        import NavBuddy.Component

        def navigation_items do
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
            }
          ]
        end
      end

  In your LiveView template:

      <.nav_menu items={navigation_items()} config={NavBuddy.default_config()} />

  ## Configuration

  NavBuddy supports extensive configuration options:

      config = %NavBuddy.Config{
        orientation: :horizontal,        # :horizontal | :vertical
        theme: :auto,                   # :light | :dark | :auto
        dropdown_trigger: :hover,       # :hover | :click
        mobile_behavior: :drawer,       # :drawer | :collapse | :overlay
        animations: true,               # boolean
        accessibility: true             # boolean
      }

  ## Navigation Structure

  Navigation items support multiple levels of nesting and different types.
  All navigation uses the `navigate` field which triggers LiveView's `push_navigate`
  to maintain the LiveView connection without page reloads.

  ### Simple Links
      %{id: "home", label: "Home", navigate: "/"}

  ### Dropdown Menus
      %{
        id: "products",
        label: "Products",
        navigate: "/products",
        dropdown: [
          %{id: "web", label: "Web Development", navigate: "/products/web"},
          %{id: "mobile", label: "Mobile Apps", navigate: "/products/mobile"}
        ]
      }

  ### Multi-level Dropdowns
      %{
        id: "services",
        label: "Services",
        dropdown: [
          %{
            id: "development",
            label: "Development",
            dropdown: [
              %{id: "frontend", label: "Frontend", navigate: "/services/frontend"},
              %{id: "backend", label: "Backend", navigate: "/services/backend"}
            ]
          }
        ]
      }

  ### Mega Menus
      %{
        id: "solutions",
        label: "Solutions",
        mega_menu: %{
          title: "Our Solutions",
          description: "Comprehensive business solutions",
          sections: [
            %{
              title: "For Small Business",
              items: [
                %{id: "starter", label: "Starter Package", navigate: "/solutions/starter"},
                %{id: "growth", label: "Growth Package", navigate: "/solutions/growth"}
              ]
            },
            %{
              title: "For Enterprise",
              items: [
                %{id: "enterprise", label: "Enterprise Suite", navigate: "/solutions/enterprise"},
                %{id: "custom", label: "Custom Solutions", navigate: "/solutions/custom"}
              ]
            }
          ]
        }
      }

  ### Permissions-based Navigation
      %{
        id: "admin",
        label: "Admin Panel",
        navigate: "/admin",
        permissions: "admin"  # Only visible to users with "admin" permission
      }

      %{
        id: "reports",
        label: "Reports",
        navigate: "/reports",
        permissions: ["manager", "admin"]  # Visible to users with either permission
      }

      %{
        id: "profile",
        label: "Profile",
        navigate: "/profile"  # No permissions = visible to everyone
      }

  ## Accessibility Features

  NavBuddy includes comprehensive accessibility support:
  - ARIA attributes for screen readers
  - Keyboard navigation (arrow keys, enter, escape, tab)
  - Focus management
  - High contrast theme support
  - Reduced motion support

  ## Mobile Optimization

  Multiple mobile behaviors are supported:
  - **Drawer**: Slide-out navigation drawer
  - **Collapse**: Collapsible menu sections
  - **Overlay**: Full-screen navigation overlay

  ## Theming

  NavBuddy supports automatic theme detection and manual theme selection:
  - Light theme
  - Dark theme
  - Auto (follows system preference)
  - Custom themes via CSS custom properties
  """

  # Note: We don't alias Config here to avoid circular dependency
  # The Config module will be referenced as NavBuddy.Config throughout

  @type nav_item :: %{
          required(:id) => String.t(),
          required(:label) => String.t(),
          optional(:navigate) => String.t(),
          optional(:icon) => String.t(),
          optional(:dropdown) => [nav_item()],
          optional(:mega_menu) => mega_menu() | simple_mega_menu(),
          optional(:active) => boolean(),
          optional(:disabled) => boolean(),
          optional(:permissions) => String.t() | [String.t()]
        }

  @type simple_mega_menu :: %{String.t() => [nav_item()]}

  @type mega_menu :: %{
          required(:title) => String.t(),
          optional(:description) => String.t(),
          required(:sections) => [mega_menu_section()]
        }

  @type mega_menu_section :: %{
          required(:title) => String.t(),
          optional(:description) => String.t(),
          required(:items) => [nav_item()]
        }

  @doc """
  Returns the default configuration for NavBuddy.

  ## Examples

      iex> config = NavBuddy.default_config()
      iex> config.orientation
      :horizontal

      iex> config = NavBuddy.default_config()
      iex> config.theme
      :auto
  """
  def default_config do
    %NavBuddy.Config{
      orientation: :horizontal,
      theme: :auto,
      dropdown_trigger: :hover,
      mobile_behavior: :drawer,
      animations: true,
      accessibility: true,
      mobile_breakpoint: 768,
      max_dropdown_depth: 5,
      auto_close_delay: 300,
      touch_gestures: true,
      analytics: false
    }
  end

  @doc """
  Validates a navigation item structure.

  Returns `{:ok, item}` if valid, `{:error, reason}` if invalid.

  ## Examples

      iex> item = %{id: "home", label: "Home", navigate: "/"}
      iex> NavBuddy.validate_nav_item(item)
      {:ok, %{id: "home", label: "Home", navigate: "/"}}

      iex> NavBuddy.validate_nav_item(%{label: "Home"})
      {:error, "Navigation item missing required field 'id'. Required fields: id (string), label (string). Optional fields: navigate, icon, dropdown, mega_menu, active, disabled, permissions"}
  """
  def validate_nav_item(item) when is_map(item) do
    with :ok <- validate_required_fields(item),
         :ok <- validate_field_types(item),
         :ok <- validate_navigation_logic(item),
         {:ok, _} <- validate_dropdown(Map.get(item, :dropdown)),
         {:ok, _} <- validate_mega_menu(Map.get(item, :mega_menu)) do
      {:ok, item}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_nav_item(item) do
    {:error, "Navigation item must be a map, got: #{inspect(item)}"}
  end

  @doc """
  Validates a list of navigation items.

  ## Examples

      iex> items = [%{id: "home", label: "Home"}]
      iex> NavBuddy.validate_nav_items(items)
      {:ok, [%{id: "home", label: "Home"}]}
  """
  def validate_nav_items(items) when is_list(items) do
    Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
      case validate_nav_item(item) do
        {:ok, validated_item} -> {:cont, {:ok, [validated_item | acc]}}
        {:error, reason} -> {:halt, {:error, "Invalid navigation item: #{reason}"}}
      end
    end)
    |> case do
      {:ok, validated_items} -> {:ok, Enum.reverse(validated_items)}
      error -> error
    end
  end

  def validate_nav_items(items) do
    {:error, "Navigation items must be a list, got: #{inspect(items)}"}
  end

  defp validate_required_fields(%{id: id, label: label})
       when is_binary(id) and is_binary(label) do
    :ok
  end

  defp validate_required_fields(%{id: id}) when is_binary(id) do
    {:error,
     "Navigation item missing required field 'label'. Required fields: id (string), label (string). Optional fields: navigate, icon, dropdown, mega_menu, active, disabled, permissions"}
  end

  defp validate_required_fields(%{label: label}) when is_binary(label) do
    {:error,
     "Navigation item missing required field 'id'. Required fields: id (string), label (string). Optional fields: navigate, icon, dropdown, mega_menu, active, disabled, permissions"}
  end

  defp validate_required_fields(%{id: id}) do
    {:error, "Navigation item field 'id' must be a string, got: #{inspect(id)}"}
  end

  defp validate_required_fields(%{label: label}) do
    {:error, "Navigation item field 'label' must be a string, got: #{inspect(label)}"}
  end

  defp validate_required_fields(_) do
    {:error,
     "Navigation item missing required fields 'id' and 'label'. Required fields: id (string), label (string). Optional fields: navigate, icon, dropdown, mega_menu, active, disabled, permissions"}
  end

  defp validate_field_types(item) do
    Enum.reduce_while(item, :ok, fn {key, value}, :ok ->
      case validate_field_type(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_field_type(:navigate, value) when is_binary(value), do: :ok
  defp validate_field_type(:navigate, nil), do: :ok

  defp validate_field_type(:navigate, value),
    do: {:error, "Field 'navigate' must be a string, got: #{inspect(value)}"}

  defp validate_field_type(:icon, value) when is_binary(value), do: :ok
  defp validate_field_type(:icon, nil), do: :ok

  defp validate_field_type(:icon, value),
    do: {:error, "Field 'icon' must be a string, got: #{inspect(value)}"}

  defp validate_field_type(:active, value) when is_boolean(value), do: :ok
  defp validate_field_type(:active, nil), do: :ok

  defp validate_field_type(:active, value),
    do: {:error, "Field 'active' must be a boolean, got: #{inspect(value)}"}

  defp validate_field_type(:disabled, value) when is_boolean(value), do: :ok
  defp validate_field_type(:disabled, nil), do: :ok

  defp validate_field_type(:disabled, value),
    do: {:error, "Field 'disabled' must be a boolean, got: #{inspect(value)}"}

  defp validate_field_type(:permissions, value) when is_binary(value), do: :ok

  defp validate_field_type(:permissions, value) when is_list(value) do
    if Enum.all?(value, &is_binary/1) do
      :ok
    else
      {:error,
       "Field 'permissions' when a list must contain only strings, got: #{inspect(value)}"}
    end
  end

  defp validate_field_type(:permissions, nil), do: :ok

  defp validate_field_type(:permissions, value),
    do:
      {:error, "Field 'permissions' must be a string or list of strings, got: #{inspect(value)}"}

  defp validate_field_type(:dropdown, value) when is_list(value), do: :ok
  defp validate_field_type(:dropdown, nil), do: :ok

  defp validate_field_type(:dropdown, value),
    do: {:error, "Field 'dropdown' must be a list of navigation items, got: #{inspect(value)}"}

  defp validate_field_type(:mega_menu, value) when is_map(value), do: :ok
  defp validate_field_type(:mega_menu, nil), do: :ok

  defp validate_field_type(:mega_menu, value),
    do: {:error, "Field 'mega_menu' must be a map, got: #{inspect(value)}"}

  # Allow id and label since they're already validated above
  defp validate_field_type(:id, _), do: :ok
  defp validate_field_type(:label, _), do: :ok

  defp validate_field_type(key, value),
    do:
      {:error,
       "Unknown field '#{key}' with value #{inspect(value)}. Allowed fields: id, label, navigate, icon, dropdown, mega_menu, active, disabled, permissions"}

  defp validate_navigation_logic(%{dropdown: dropdown, mega_menu: mega_menu})
       when not is_nil(dropdown) and not is_nil(mega_menu) do
    {:error,
     "Navigation item cannot have both 'dropdown' and 'mega_menu'. Choose one or the other."}
  end

  defp validate_navigation_logic(%{dropdown: dropdown, navigate: navigate})
       when not is_nil(dropdown) and not is_nil(navigate) do
    {:error,
     "Navigation item with 'dropdown' should not have 'navigate' field. Dropdown items should navigate through their child items."}
  end

  defp validate_navigation_logic(%{mega_menu: mega_menu, navigate: navigate})
       when not is_nil(mega_menu) and not is_nil(navigate) do
    {:error,
     "Navigation item with 'mega_menu' should not have 'navigate' field. Mega menu items should navigate through their child items."}
  end

  defp validate_navigation_logic(_), do: :ok

  defp validate_dropdown(nil), do: {:ok, nil}

  defp validate_dropdown(dropdown) when is_list(dropdown) do
    case validate_nav_items(dropdown) do
      {:ok, _} -> {:ok, dropdown}
      {:error, reason} -> {:error, "Invalid dropdown items: #{reason}"}
    end
  end

  defp validate_dropdown(dropdown),
    do: {:error, "Dropdown must be a list of navigation items, got: #{inspect(dropdown)}"}

  defp validate_mega_menu(nil), do: {:ok, nil}

  # Handle simple mega menu: %{"Category" => [items]}
  defp validate_mega_menu(mega_menu) when is_map(mega_menu) do
    # Check if it's a simple mega menu (all values are lists)
    if Enum.all?(mega_menu, fn {key, value} -> is_binary(key) and is_list(value) end) do
      validate_simple_mega_menu(mega_menu)
    else
      validate_structured_mega_menu(mega_menu)
    end
  end

  defp validate_mega_menu(mega_menu),
    do: {:error, "Mega menu must be a map, got: #{inspect(mega_menu)}"}

  defp validate_simple_mega_menu(mega_menu) do
    Enum.reduce_while(mega_menu, {:ok, mega_menu}, fn {category, items}, {:ok, acc} ->
      case validate_nav_items(items) do
        {:ok, _} ->
          {:cont, {:ok, acc}}

        {:error, reason} ->
          {:halt, {:error, "Invalid items in mega menu category '#{category}': #{reason}"}}
      end
    end)
  end

  defp validate_structured_mega_menu(%{title: title, sections: sections})
       when is_binary(title) and is_list(sections) do
    case validate_mega_menu_sections(sections) do
      {:ok, _} -> {:ok, %{title: title, sections: sections}}
      {:error, reason} -> {:error, "Invalid mega menu sections: #{reason}"}
    end
  end

  defp validate_structured_mega_menu(%{sections: sections}) when is_list(sections) do
    {:error,
     "Structured mega menu missing required field 'title'. Required: title (string), sections (list). Optional: description (string)"}
  end

  defp validate_structured_mega_menu(%{title: title}) when is_binary(title) do
    {:error,
     "Structured mega menu missing required field 'sections'. Required: title (string), sections (list). Optional: description (string)"}
  end

  defp validate_structured_mega_menu(%{title: title}) do
    {:error, "Structured mega menu field 'title' must be a string, got: #{inspect(title)}"}
  end

  defp validate_structured_mega_menu(%{sections: sections}) do
    {:error, "Structured mega menu field 'sections' must be a list, got: #{inspect(sections)}"}
  end

  defp validate_structured_mega_menu(mega_menu) do
    {:error,
     "Structured mega menu missing required fields. Required: title (string), sections (list). Optional: description (string). Got: #{inspect(mega_menu)}"}
  end

  defp validate_mega_menu_sections(sections) do
    Enum.reduce_while(sections, {:ok, []}, fn section, {:ok, acc} ->
      case validate_mega_menu_section(section) do
        {:ok, validated_section} -> {:cont, {:ok, [validated_section | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, validated_sections} -> {:ok, Enum.reverse(validated_sections)}
      error -> error
    end
  end

  defp validate_mega_menu_section(%{title: title, items: items})
       when is_binary(title) and is_list(items) do
    case validate_nav_items(items) do
      {:ok, _} -> {:ok, %{title: title, items: items}}
      {:error, reason} -> {:error, "Invalid items in mega menu section '#{title}': #{reason}"}
    end
  end

  defp validate_mega_menu_section(%{items: items}) when is_list(items) do
    {:error,
     "Mega menu section missing required field 'title'. Required: title (string), items (list). Optional: description (string)"}
  end

  defp validate_mega_menu_section(%{title: title}) when is_binary(title) do
    {:error,
     "Mega menu section missing required field 'items'. Required: title (string), items (list). Optional: description (string)"}
  end

  defp validate_mega_menu_section(%{title: title}) do
    {:error, "Mega menu section field 'title' must be a string, got: #{inspect(title)}"}
  end

  defp validate_mega_menu_section(%{items: items}) do
    {:error, "Mega menu section field 'items' must be a list, got: #{inspect(items)}"}
  end

  defp validate_mega_menu_section(section) do
    {:error,
     "Mega menu section must have 'title' (string) and 'items' (list). Got: #{inspect(section)}"}
  end

  @doc """
  Creates a simple navigation item.

  ## Examples

      iex> NavBuddy.nav_item("home", "Home", "/")
      %{id: "home", label: "Home", navigate: "/"}

      iex> NavBuddy.nav_item("admin", "Admin", "/admin", permissions: "admin")
      %{id: "admin", label: "Admin", navigate: "/admin", permissions: "admin"}
  """
  def nav_item(id, label, navigate \\ nil, opts \\ []) do
    base = %{id: id, label: label}

    base = if navigate, do: Map.put(base, :navigate, navigate), else: base

    Enum.reduce(opts, base, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  @doc """
  Creates a navigation item with dropdown.

  ## Examples

      iex> dropdown_items = [
      ...>   %{id: "web", label: "Web Apps", navigate: "/products/web"},
      ...>   %{id: "mobile", label: "Mobile Apps", navigate: "/products/mobile"}
      ...> ]
      iex> NavBuddy.dropdown_item("products", "Products", dropdown_items)
      %{id: "products", label: "Products", dropdown: [%{id: "web", label: "Web Apps", navigate: "/products/web"}, %{id: "mobile", label: "Mobile Apps", navigate: "/products/mobile"}]}
  """
  def dropdown_item(id, label, dropdown_items, opts \\ []) do
    base = %{id: id, label: label, dropdown: dropdown_items}

    Enum.reduce(opts, base, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  @doc """
  Creates a navigation item with simple mega menu.

  ## Examples

      iex> categories = %{
      ...>   "Frontend" => [%{id: "react", label: "React", navigate: "/tools/react"}],
      ...>   "Backend" => [%{id: "elixir", label: "Elixir", navigate: "/tools/elixir"}]
      ...> }
      iex> NavBuddy.mega_menu_item("tools", "Tools", categories)
      %{id: "tools", label: "Tools", mega_menu: %{"Frontend" => [%{id: "react", label: "React", navigate: "/tools/react"}], "Backend" => [%{id: "elixir", label: "Elixir", navigate: "/tools/elixir"}]}}
  """
  def mega_menu_item(id, label, categories, opts \\ []) do
    base = %{id: id, label: label, mega_menu: categories}

    Enum.reduce(opts, base, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  @doc """
  Filters navigation items based on user permissions.

  Removes items that the user doesn't have permission to see. Items without
  permissions are always visible. When an item has a list of permissions,
  the user must have ALL of them to see the item.

  ## Examples

      iex> items = [
      ...>   %{id: "home", label: "Home", navigate: "/"},
      ...>   %{id: "admin", label: "Admin", navigate: "/admin", permissions: "admin"},
      ...>   %{id: "user", label: "Profile", navigate: "/profile", permissions: "user"}
      ...> ]
      iex> NavBuddy.filter_by_permissions(items, ["user"])
      [
        %{id: "home", label: "Home", navigate: "/"},
        %{id: "user", label: "Profile", navigate: "/profile", permissions: "user"}
      ]
  """
  def filter_by_permissions(items, user_permissions)
      when is_list(items) and is_list(user_permissions) do
    Enum.filter(items, &has_permission?(&1, user_permissions))
    |> Enum.map(&filter_item_permissions(&1, user_permissions))
    |> Enum.filter(&item_has_content?/1)
  end

  def filter_by_permissions(items, user_permissions)
      when is_list(items) and is_binary(user_permissions) do
    filter_by_permissions(items, [user_permissions])
  end

  def filter_by_permissions(items, _) when is_list(items) do
    items
  end

  defp has_permission?(%{permissions: nil}, _), do: true

  defp has_permission?(%{permissions: item_perms}, user_perms) when is_binary(item_perms) do
    item_perms in user_perms
  end

  defp has_permission?(%{permissions: item_perms}, user_perms) when is_list(item_perms) do
    # Item requires ALL permissions in the list
    Enum.all?(item_perms, &(&1 in user_perms))
  end

  defp has_permission?(_, _), do: true

  defp filter_item_permissions(item, user_permissions) do
    item
    |> filter_dropdown_permissions(user_permissions)
    |> filter_mega_menu_permissions(user_permissions)
  end

  defp filter_dropdown_permissions(%{dropdown: dropdown} = item, user_permissions)
       when is_list(dropdown) do
    filtered_dropdown = filter_by_permissions(dropdown, user_permissions)
    %{item | dropdown: filtered_dropdown}
  end

  defp filter_dropdown_permissions(item, _), do: item

  defp filter_mega_menu_permissions(%{mega_menu: mega_menu} = item, user_permissions)
       when is_map(mega_menu) do
    case mega_menu do
      # Handle simple map structure: %{"category" => [items]}
      %{sections: _} = structured_mega_menu ->
        filtered_sections =
          Enum.map(structured_mega_menu.sections, fn section ->
            %{section | items: filter_by_permissions(section.items, user_permissions)}
          end)

        %{item | mega_menu: %{structured_mega_menu | sections: filtered_sections}}

      # Handle simple map structure: %{"category" => [items]}
      simple_mega_menu ->
        filtered_mega_menu =
          simple_mega_menu
          |> Enum.map(fn {category, items} ->
            {category, filter_by_permissions(items, user_permissions)}
          end)
          |> Enum.filter(fn {_category, items} -> length(items) > 0 end)
          |> Enum.into(%{})

        %{item | mega_menu: filtered_mega_menu}
    end
  end

  defp filter_mega_menu_permissions(item, _), do: item

  # Check if an item still has content after filtering
  defp item_has_content?(%{dropdown: dropdown}) when is_list(dropdown) do
    length(dropdown) > 0
  end

  defp item_has_content?(%{mega_menu: mega_menu}) when is_map(mega_menu) do
    case mega_menu do
      %{sections: sections} when is_list(sections) ->
        Enum.any?(sections, fn section -> length(section.items) > 0 end)

      simple_mega_menu ->
        map_size(simple_mega_menu) > 0
    end
  end

  defp item_has_content?(_), do: true

  @doc """
  Generates a unique menu ID for accessibility.

  ## Examples

      iex> NavBuddy.generate_menu_id("main-nav", "products")
      "main-nav-products-menu"
  """
  def generate_menu_id(nav_id, item_id) do
    "#{nav_id}-#{item_id}-menu"
  end

  @doc """
  Finds the active navigation item based on the current path.

  ## Examples

      iex> items = [%{id: "home", navigate: "/"}, %{id: "about", navigate: "/about"}]
      iex> NavBuddy.find_active_item(items, "/about")
      [%{id: "home", navigate: "/", active: false}, %{id: "about", navigate: "/about", active: true}]
  """
  def find_active_item(items, current_path) when is_list(items) and is_binary(current_path) do
    Enum.map(items, fn item ->
      active = determine_active(item, current_path)
      Map.put(item, :active, active)
    end)
  end

  defp determine_active(%{navigate: navigate} = item, current_path) when is_binary(navigate) do
    cond do
      navigate == current_path -> true
      has_dropdown_active?(Map.get(item, :dropdown), current_path) -> true
      has_mega_menu_active?(Map.get(item, :mega_menu), current_path) -> true
      true -> false
    end
  end

  defp determine_active(_, _), do: false

  defp has_dropdown_active?(nil, _), do: false

  defp has_dropdown_active?(dropdown, current_path) when is_list(dropdown) do
    Enum.any?(dropdown, &determine_active(&1, current_path))
  end

  defp has_mega_menu_active?(nil, _), do: false

  defp has_mega_menu_active?(%{sections: sections}, current_path) when is_list(sections) do
    Enum.any?(sections, fn %{items: items} ->
      Enum.any?(items, &determine_active(&1, current_path))
    end)
  end

  @doc """
  Generates breadcrumb navigation from the active path.

  ## Examples

      iex> items = [%{id: "home", label: "Home", navigate: "/"}]
      iex> NavBuddy.generate_breadcrumbs(items, "/")
      [%{id: "home", label: "Home", navigate: "/"}]
  """
  def generate_breadcrumbs(items, current_path) when is_list(items) and is_binary(current_path) do
    case find_breadcrumb_path(items, current_path, []) do
      [] -> []
      path -> Enum.reverse(path)
    end
  end

  defp find_breadcrumb_path([], _, _), do: []

  defp find_breadcrumb_path([item | rest], current_path, path) do
    case find_in_item(item, current_path, [item | path]) do
      [] -> find_breadcrumb_path(rest, current_path, path)
      found_path -> found_path
    end
  end

  defp find_in_item(%{navigate: navigate}, current_path, path) when navigate == current_path do
    path
  end

  defp find_in_item(%{dropdown: dropdown} = item, current_path, path) when is_list(dropdown) do
    case find_breadcrumb_path(dropdown, current_path, [item | path]) do
      [] -> []
      found_path -> found_path
    end
  end

  defp find_in_item(%{mega_menu: %{sections: sections}}, current_path, path)
       when is_list(sections) do
    sections
    |> Enum.flat_map(fn %{items: items} -> items end)
    |> find_breadcrumb_path(current_path, path)
  end

  defp find_in_item(_, _, _), do: []

  @doc """
  Example navigation items showcasing all features.

  Returns a comprehensive navigation structure demonstrating:
  - Simple links
  - Single-level dropdowns
  - Multi-level dropdowns
  - Mega menus
  - Icons and descriptions
  """
  def example_navigation do
    [
      %{
        id: "home",
        label: "Home",
        href: "/",
        icon: "home"
      },
      %{
        id: "products",
        label: "Products",
        href: "/products",
        icon: "package",
        dropdown: [
          %{
            id: "web-apps",
            label: "Web Applications",
            href: "/products/web",
            icon: "globe"
          },
          %{
            id: "mobile-apps",
            label: "Mobile Applications",
            href: "/products/mobile",
            icon: "smartphone"
          },
          %{
            id: "desktop",
            label: "Desktop Software",
            href: "/products/desktop",
            icon: "monitor"
          }
        ]
      },
      %{
        id: "services",
        label: "Services",
        icon: "settings",
        dropdown: [
          %{
            id: "development",
            label: "Development",
            icon: "code",
            dropdown: [
              %{id: "frontend", label: "Frontend Development", href: "/services/frontend"},
              %{id: "backend", label: "Backend Development", href: "/services/backend"},
              %{id: "fullstack", label: "Full Stack Development", href: "/services/fullstack"}
            ]
          },
          %{
            id: "design",
            label: "Design",
            icon: "palette",
            dropdown: [
              %{id: "ui-design", label: "UI Design", href: "/services/ui"},
              %{id: "ux-design", label: "UX Design", href: "/services/ux"},
              %{id: "branding", label: "Branding", href: "/services/branding"}
            ]
          },
          %{
            id: "consulting",
            label: "Consulting",
            href: "/services/consulting",
            icon: "users"
          }
        ]
      },
      %{
        id: "solutions",
        label: "Solutions",
        icon: "layers",
        mega_menu: %{
          title: "Business Solutions",
          description: "Comprehensive solutions tailored to your business needs",
          sections: [
            %{
              title: "For Small Business",
              description: "Perfect for startups and growing companies",
              items: [
                %{
                  id: "starter",
                  label: "Starter Package",
                  href: "/solutions/starter",
                  icon: "zap"
                },
                %{
                  id: "growth",
                  label: "Growth Package",
                  href: "/solutions/growth",
                  icon: "trending-up"
                },
                %{id: "pro", label: "Professional", href: "/solutions/pro", icon: "star"}
              ]
            },
            %{
              title: "For Enterprise",
              description: "Scalable solutions for large organizations",
              items: [
                %{
                  id: "enterprise",
                  label: "Enterprise Suite",
                  href: "/solutions/enterprise",
                  icon: "building"
                },
                %{
                  id: "custom",
                  label: "Custom Solutions",
                  href: "/solutions/custom",
                  icon: "tool"
                },
                %{
                  id: "support",
                  label: "24/7 Support",
                  href: "/solutions/support",
                  icon: "headphones"
                }
              ]
            },
            %{
              title: "Industry Specific",
              description: "Specialized solutions by industry",
              items: [
                %{
                  id: "healthcare",
                  label: "Healthcare",
                  href: "/solutions/healthcare",
                  icon: "heart"
                },
                %{
                  id: "finance",
                  label: "Financial Services",
                  href: "/solutions/finance",
                  icon: "dollar-sign"
                },
                %{id: "education", label: "Education", href: "/solutions/education", icon: "book"}
              ]
            }
          ]
        }
      },
      %{
        id: "about",
        label: "About",
        href: "/about",
        icon: "info"
      },
      %{
        id: "contact",
        label: "Contact",
        href: "/contact",
        icon: "mail"
      }
    ]
  end
end
