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

  Navigation items support multiple levels of nesting and different types:

  ### Simple Links
      %{id: "home", label: "Home", href: "/"}

  ### Dropdown Menus
      %{
        id: "products",
        label: "Products",
        href: "/products",
        dropdown: [
          %{id: "web", label: "Web Development", href: "/products/web"},
          %{id: "mobile", label: "Mobile Apps", href: "/products/mobile"}
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
              %{id: "frontend", label: "Frontend", href: "/services/frontend"},
              %{id: "backend", label: "Backend", href: "/services/backend"}
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
                %{id: "starter", label: "Starter Package", href: "/solutions/starter"},
                %{id: "growth", label: "Growth Package", href: "/solutions/growth"}
              ]
            },
            %{
              title: "For Enterprise",
              items: [
                %{id: "enterprise", label: "Enterprise Suite", href: "/solutions/enterprise"},
                %{id: "custom", label: "Custom Solutions", href: "/solutions/custom"}
              ]
            }
          ]
        }
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
          id: String.t(),
          label: String.t(),
          href: String.t() | nil,
          icon: String.t() | nil,
          dropdown: [nav_item()] | nil,
          mega_menu: mega_menu() | nil,
          active: boolean() | nil,
          disabled: boolean() | nil
        }

  @type mega_menu :: %{
          title: String.t(),
          description: String.t() | nil,
          sections: [mega_menu_section()]
        }

  @type mega_menu_section :: %{
          title: String.t(),
          description: String.t() | nil,
          items: [nav_item()]
        }

  @doc """
  Returns the default configuration for NavBuddy.

  ## Examples

      iex> config = NavBuddy.default_config()
      iex> config.orientation
      :horizontal

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

      iex> item = %{id: "home", label: "Home", href: "/"}
      iex> NavBuddy.validate_nav_item(item)
      {:ok, %{id: "home", label: "Home", href: "/"}}

      iex> NavBuddy.validate_nav_item(%{label: "Home"})
      {:error, "Navigation item must have an id"}
  """
  def validate_nav_item(%{id: id, label: label} = item) when is_binary(id) and is_binary(label) do
    with {:ok, _} <- validate_dropdown(Map.get(item, :dropdown)),
         {:ok, _} <- validate_mega_menu(Map.get(item, :mega_menu)) do
      {:ok, item}
    end
  end

  def validate_nav_item(%{label: _}) do
    {:error, "Navigation item must have an id"}
  end

  def validate_nav_item(%{id: _}) do
    {:error, "Navigation item must have a label"}
  end

  def validate_nav_item(_) do
    {:error, "Navigation item must have id and label"}
  end

  defp validate_dropdown(nil), do: {:ok, nil}

  defp validate_dropdown(dropdown) when is_list(dropdown) do
    case Enum.find(dropdown, fn item -> 
      case validate_nav_item(item) do
        {:ok, _} -> false
        {:error, _} -> true
      end
    end) do
      nil -> {:ok, dropdown}
      _invalid -> {:error, "Invalid item in dropdown"}
    end
  end

  defp validate_dropdown(_), do: {:error, "Dropdown must be a list"}

  defp validate_mega_menu(nil), do: {:ok, nil}

  defp validate_mega_menu(%{title: title, sections: sections}) when is_binary(title) and is_list(sections) do
    case validate_mega_menu_sections(sections) do
      {:ok, _} -> {:ok, %{title: title, sections: sections}}
      error -> error
    end
  end

  defp validate_mega_menu(_), do: {:error, "Mega menu must have title and sections"}

  defp validate_mega_menu_sections(sections) do
    case Enum.find(sections, &validate_mega_menu_section/1) do
      nil -> {:ok, sections}
      _invalid -> {:error, "Invalid section in mega menu"}
    end
  end

  defp validate_mega_menu_section(%{title: title, items: items}) when is_binary(title) and is_list(items) do
    case Enum.find(items, fn item -> 
      case validate_nav_item(item) do
        {:ok, _} -> false
        {:error, _} -> true
      end
    end) do
      nil -> false
      _invalid -> true
    end
  end

  defp validate_mega_menu_section(_), do: true

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

      iex> items = [%{id: "home", href: "/"}, %{id: "about", href: "/about"}]
      iex> NavBuddy.find_active_item(items, "/about")
      %{id: "about", href: "/about", active: true}
  """
  def find_active_item(items, current_path) when is_list(items) and is_binary(current_path) do
    Enum.map(items, fn item ->
      active = determine_active(item, current_path)
      Map.put(item, :active, active)
    end)
  end

  defp determine_active(%{href: href} = item, current_path) when is_binary(href) do
    cond do
      href == current_path -> true
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

      iex> items = [
      ...>   %{id: "home", label: "Home", href: "/"},
      ...>   %{id: "products", label: "Products", href: "/products", dropdown: [
      ...>     %{id: "web", label: "Web Apps", href: "/products/web"}
      ...>   ]}
      ...> ]
      iex> NavBuddy.generate_breadcrumbs(items, "/products/web")
      [
      %{id: "home", label: "Home", href: "/"},
      %{id: "products", label: "Products", href: "/products"},
      %{id: "web", label: "Web Apps", href: "/products/web"}
      ]
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

  defp find_in_item(%{href: href}, current_path, path) when href == current_path do
    path
  end

  defp find_in_item(%{dropdown: dropdown} = item, current_path, path) when is_list(dropdown) do
    case find_breadcrumb_path(dropdown, current_path, [item | path]) do
      [] -> []
      found_path -> found_path
    end
  end

  defp find_in_item(%{mega_menu: %{sections: sections}}, current_path, path) when is_list(sections) do
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
                %{id: "starter", label: "Starter Package", href: "/solutions/starter", icon: "zap"},
                %{id: "growth", label: "Growth Package", href: "/solutions/growth", icon: "trending-up"},
                %{id: "pro", label: "Professional", href: "/solutions/pro", icon: "star"}
              ]
            },
            %{
              title: "For Enterprise",
              description: "Scalable solutions for large organizations",
              items: [
                %{id: "enterprise", label: "Enterprise Suite", href: "/solutions/enterprise", icon: "building"},
                %{id: "custom", label: "Custom Solutions", href: "/solutions/custom", icon: "tool"},
                %{id: "support", label: "24/7 Support", href: "/solutions/support", icon: "headphones"}
              ]
            },
            %{
              title: "Industry Specific",
              description: "Specialized solutions by industry",
              items: [
                %{id: "healthcare", label: "Healthcare", href: "/solutions/healthcare", icon: "heart"},
                %{id: "finance", label: "Financial Services", href: "/solutions/finance", icon: "dollar-sign"},
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