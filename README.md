# NavBuddy

[![Hex version badge](https://img.shields.io/hexpm/v/navbuddy.svg)](https://hex.pm/packages/navbuddy)
[![Hex docs badge](https://img.shields.io/badge/hex-docs-green.svg)](https://hexdocs.pm/navbuddy)
[![License badge](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/SangRJ/navbuddy/blob/main/LICENSE)

**Advanced Configurable Navigation Component for Phoenix LiveView**

NavBuddy provides comprehensive navigation components for Phoenix LiveView applications, featuring dropdowns, mega menus, mobile-responsive design, and full accessibility support.

## Features

- 🎯 **Advanced Menu System**: Single-layer dropdowns, multi-layer dropdowns, and mega menus
- 📱 **Mobile-Responsive**: Drawer, collapse, and overlay modes for mobile devices
- ♿ **Accessibility First**: WCAG 2.1 AA compliant with screen reader support
- ⌨️ **Keyboard Navigation**: Full arrow key navigation with focus management
- 🎨 **Theming**: Light/dark/auto themes with CSS custom properties
- 🔧 **Highly Configurable**: Extensive configuration options
- 🚀 **LiveView Integration**: Seamless Phoenix LiveView event handling
- 📊 **Analytics Ready**: Built-in event tracking support

## Quick Start

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:navbuddy, "~> 0.1.0"}
  ]
end
```

Include the CSS and JavaScript in your layout:

```html
<link rel="stylesheet" href="/assets/navbuddy.css" />
<script src="/assets/navbuddy.js"></script>
```

Use in your LiveView:

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  import NavBuddy.Component

  def mount(_params, _session, socket) do
    socket = assign(socket, :navigation_items, navigation_items())
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.nav_menu items={@navigation_items} current_path={@current_path} />
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
      }
    ]
  end
end
```

## Navigation Structure

### Simple Links

```elixir
%{id: "home", label: "Home", navigate: "/", icon: "home"}
```

### Single-Layer Dropdowns

```elixir
%{
  id: "products",
  label: "Products",
  navigate: "/products",
  icon: "package",
  dropdown: [
    %{id: "web", label: "Web Development", navigate: "/products/web"},
    %{id: "mobile", label: "Mobile Apps", navigate: "/products/mobile"}
  ]
}
```

### Multi-Layer Dropdowns

```elixir
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
```

### Mega Menus

```elixir
%{
  id: "solutions",
  label: "Solutions",
  mega_menu: %{
    title: "Our Solutions",
    description: "Comprehensive business solutions",
    sections: [
      %{
        title: "For Small Business",
        description: "Perfect for startups",
        items: [
          %{id: "starter", label: "Starter Package", navigate: "/solutions/starter"},
          %{id: "growth", label: "Growth Package", navigate: "/solutions/growth"}
        ]
      },
      %{
        title: "For Enterprise",
        description: "Scalable solutions",
        items: [
          %{id: "enterprise", label: "Enterprise Suite", navigate: "/solutions/enterprise"},
          %{id: "custom", label: "Custom Solutions", navigate: "/solutions/custom"}
        ]
      }
    ]
  }
}
```

## Configuration

Create a configuration struct:

```elixir
config = %NavBuddy.Config{
  orientation: :horizontal,        # :horizontal | :vertical
  theme: :auto,                   # :light | :dark | :auto
  dropdown_trigger: :hover,       # :hover | :click
  mobile_behavior: :drawer,       # :drawer | :collapse | :overlay
  animations: true,               # boolean
  accessibility: true,            # boolean
  mobile_breakpoint: 768,         # pixels
  max_dropdown_depth: 5,          # levels
  auto_close_delay: 300,          # milliseconds
  touch_gestures: true,           # boolean
  analytics: false                # boolean
}
```

Use with your navigation:

```elixir
<.nav_menu items={@navigation_items} config={config} current_path={@current_path} />
```

## LiveView Integration

NavBuddy includes comprehensive LiveView helpers:

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  use NavBuddy.LiveHelpers  # Adds event handlers

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_navbuddy_state()
      |> assign(:navigation_items, navigation_items())

    {:ok, socket}
  end

  # Event handlers are automatically available:
  # handle_event("navbuddy:item_click", ...)
  # handle_event("navbuddy:dropdown_toggle", ...)
  # handle_event("navbuddy:mobile_toggle", ...)
end
```

## Mobile Optimization

### Drawer Mode (Default)

Slide-out navigation drawer on mobile:

```elixir
%NavBuddy.Config{mobile_behavior: :drawer}
```

### Collapse Mode

Collapsible menu sections:

```elixir
%NavBuddy.Config{mobile_behavior: :collapse}
```

### Overlay Mode

Full-screen navigation overlay:

```elixir
%NavBuddy.Config{mobile_behavior: :overlay}
```

## Theming

### Automatic Theme Detection

```elixir
%NavBuddy.Config{theme: :auto}  # Follows system preference
```

### Manual Theme Selection

```elixir
%NavBuddy.Config{theme: :light}  # or :dark
```

### Custom Themes

Override CSS custom properties:

```css
:root {
  --navbuddy-bg-primary: #your-color;
  --navbuddy-text-primary: #your-color;
  --navbuddy-accent-primary: #your-color;
}
```

## Accessibility Features

NavBuddy is built with accessibility in mind:

- **ARIA Support**: Proper ARIA labels, roles, and states
- **Keyboard Navigation**: Full keyboard support with arrow keys
- **Screen Readers**: Compatible with screen reader software
- **Focus Management**: Intelligent focus handling
- **High Contrast**: Support for high contrast themes
- **Reduced Motion**: Respects `prefers-reduced-motion`

### Keyboard Navigation

- **Arrow Keys**: Navigate between menu items
- **Enter/Space**: Activate menu items
- **Escape**: Close menus and return focus
- **Home/End**: Jump to first/last items
- **Tab**: Standard tab navigation

## Breadcrumbs

Automatic breadcrumb generation:

```elixir
<.nav_breadcrumbs
  items={@navigation_items}
  current_path={@current_path}
/>
```

## Advanced Features

### Smart Positioning

Automatically adjusts dropdown and mega menu positions to stay within viewport:

```elixir
%NavBuddy.Config{smart_positioning: true}
```

### Touch Gestures

Mobile-optimized touch interactions:

```elixir
%NavBuddy.Config{touch_gestures: true}
```

### Analytics Integration

Built-in event tracking:

```elixir
%NavBuddy.Config{analytics: true}

# Events emitted:
# navbuddy:item_click
# navbuddy:dropdown_open
# navbuddy:dropdown_close
# navbuddy:mobile_toggle
```

### Animation Control

Control animations:

```elixir
%NavBuddy.Config{animations: true, auto_close_delay: 300}
```

## CSS Classes

NavBuddy provides semantic CSS classes for customization:

- `.navbuddy-nav` - Main navigation container
- `.navbuddy-nav-item` - Navigation item wrapper
- `.navbuddy-nav-link` - Navigation links
- `.navbuddy-dropdown` - Dropdown menus
- `.navbuddy-mega-menu` - Mega menus
- `.navbuddy-mobile-toggle` - Mobile menu toggle
- `.navbuddy-breadcrumbs` - Breadcrumb navigation

## JavaScript API

Access the JavaScript API directly:

```javascript
// Initialize manually
const nav = new NavBuddy(document.querySelector(".navbuddy-nav"), {
  smartPositioning: true,
  keyboardNavigation: true,
  analytics: true,
});

// Methods
nav.openDropdown("products");
nav.closeMegaMenu("solutions");
nav.toggleMobileNav();
nav.closeAllMenus();

// Events
nav.trackEvent("custom_event", { custom: "data" });

// State
const state = nav.getState();
```

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Examples

Check out the included example navigation structure:

```elixir
NavBuddy.example_navigation()
```

This returns a comprehensive navigation structure showcasing all features:

- Simple links with icons
- Single and multi-level dropdowns
- Mega menus with grid layouts
- Mixed navigation types

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Changelog

### v0.1.0 (2025-01-25)

- Initial release
- Advanced dropdown and mega menu support
- Mobile-responsive design
- Full accessibility implementation
- Comprehensive theming system
- LiveView integration
- Touch gesture support
- Analytics integration

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Phoenix LiveView team for the excellent framework
- Tailwind CSS for design inspiration
- Accessibility guidelines from WCAG 2.1

---

**Made with ❤️ for the Phoenix community**
