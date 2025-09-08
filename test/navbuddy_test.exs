defmodule NavBuddyTest do
  use ExUnit.Case
  doctest NavBuddy

  describe "default_config/0" do
    test "returns valid configuration" do
      config = NavBuddy.default_config()
      assert %NavBuddy.Config{} = config
      assert config.orientation == :horizontal
      assert config.theme == :auto
      assert config.dropdown_trigger == :hover
      assert config.mobile_behavior == :drawer
    end
  end

  describe "validate_nav_item/1" do
    test "validates basic nav item" do
      item = %{id: "home", label: "Home", navigate: "/"}
      assert {:ok, ^item} = NavBuddy.validate_nav_item(item)
    end

    test "rejects item without id" do
      item = %{label: "Home", navigate: "/"}
      assert {:error, _} = NavBuddy.validate_nav_item(item)
    end

    test "rejects item without label" do
      item = %{id: "home", navigate: "/"}
      assert {:error, _} = NavBuddy.validate_nav_item(item)
    end
  end

  describe "generate_menu_id/2" do
    test "generates unique menu id" do
      id = NavBuddy.generate_menu_id("main-nav", "products")
      assert is_binary(id)
      assert id == "main-nav-products-menu"
    end
  end

  describe "find_active_item/2" do
    test "finds active item by path" do
      items = [
        %{id: "home", label: "Home", navigate: "/"},
        %{id: "about", label: "About", navigate: "/about"}
      ]

      result = NavBuddy.find_active_item(items, "/about")
      about_item = Enum.find(result, &(&1.id == "about"))
      assert about_item.active == true
    end
  end

  describe "filter_by_permissions/2" do
    test "returns all items when user_permissions is nil" do
      items = [
        %{id: "home", label: "Home", navigate: "/", permissions: "read"},
        %{id: "admin", label: "Admin", navigate: "/admin", permissions: "admin"}
      ]

      result = NavBuddy.filter_by_permissions(items, nil)
      assert length(result) == 2
    end

    test "filters items based on string permissions" do
      items = [
        %{id: "home", label: "Home", navigate: "/", permissions: "read"},
        %{id: "admin", label: "Admin", navigate: "/admin", permissions: "admin"},
        %{id: "public", label: "Public", navigate: "/public"}
      ]

      result = NavBuddy.filter_by_permissions(items, "read")
      # home and public (no permissions required)
      assert length(result) == 2
      assert Enum.any?(result, &(&1.id == "home"))
      assert Enum.any?(result, &(&1.id == "public"))
      refute Enum.any?(result, &(&1.id == "admin"))
    end

    test "filters items based on list permissions" do
      items = [
        %{id: "home", label: "Home", navigate: "/", permissions: "read"},
        %{id: "admin", label: "Admin", navigate: "/admin", permissions: "admin"},
        %{id: "write", label: "Write", navigate: "/write", permissions: "write"},
        %{id: "public", label: "Public", navigate: "/public"}
      ]

      result = NavBuddy.filter_by_permissions(items, ["read", "write"])
      # home, write, and public
      assert length(result) == 3
      assert Enum.any?(result, &(&1.id == "home"))
      assert Enum.any?(result, &(&1.id == "write"))
      assert Enum.any?(result, &(&1.id == "public"))
      refute Enum.any?(result, &(&1.id == "admin"))
    end

    test "handles list of required permissions (item requires multiple permissions)" do
      items = [
        %{id: "home", label: "Home", navigate: "/", permissions: ["read", "basic"]},
        %{id: "admin", label: "Admin", navigate: "/admin", permissions: ["admin", "super"]},
        %{id: "public", label: "Public", navigate: "/public"}
      ]

      # User has read but not basic
      result = NavBuddy.filter_by_permissions(items, ["read"])
      # only public
      assert length(result) == 1
      assert Enum.any?(result, &(&1.id == "public"))

      # User has both read and basic
      result = NavBuddy.filter_by_permissions(items, ["read", "basic"])
      # home and public
      assert length(result) == 2
      assert Enum.any?(result, &(&1.id == "home"))
      assert Enum.any?(result, &(&1.id == "public"))
    end

    test "filters nested dropdown items" do
      items = [
        %{
          id: "menu",
          label: "Menu",
          dropdown: [
            %{id: "item1", label: "Item 1", navigate: "/item1", permissions: "read"},
            %{id: "item2", label: "Item 2", navigate: "/item2", permissions: "admin"},
            %{id: "item3", label: "Item 3", navigate: "/item3"}
          ]
        }
      ]

      result = NavBuddy.filter_by_permissions(items, "read")
      dropdown_items = hd(result).dropdown
      # item1 and item3
      assert length(dropdown_items) == 2
      assert Enum.any?(dropdown_items, &(&1.id == "item1"))
      assert Enum.any?(dropdown_items, &(&1.id == "item3"))
      refute Enum.any?(dropdown_items, &(&1.id == "item2"))
    end

    test "filters nested mega-menu items" do
      items = [
        %{
          id: "products",
          label: "Products",
          mega_menu: %{
            "category1" => [
              %{id: "prod1", label: "Product 1", navigate: "/prod1", permissions: "read"},
              %{id: "prod2", label: "Product 2", navigate: "/prod2", permissions: "admin"}
            ],
            "category2" => [
              %{id: "prod3", label: "Product 3", navigate: "/prod3"}
            ]
          }
        }
      ]

      result = NavBuddy.filter_by_permissions(items, "read")
      mega_menu = hd(result).mega_menu

      category1_items = mega_menu["category1"]
      # only prod1
      assert length(category1_items) == 1
      assert hd(category1_items).id == "prod1"

      category2_items = mega_menu["category2"]
      # prod3 (no permissions required)
      assert length(category2_items) == 1
    end

    test "removes dropdown parent if all children are filtered out" do
      items = [
        %{
          id: "admin_menu",
          label: "Admin Menu",
          dropdown: [
            %{id: "admin1", label: "Admin 1", navigate: "/admin1", permissions: "admin"},
            %{id: "admin2", label: "Admin 2", navigate: "/admin2", permissions: "admin"}
          ]
        },
        %{id: "public", label: "Public", navigate: "/public"}
      ]

      result = NavBuddy.filter_by_permissions(items, "read")
      assert length(result) == 1
      assert hd(result).id == "public"
    end

    test "removes mega-menu parent if all categories are empty" do
      items = [
        %{
          id: "admin_products",
          label: "Admin Products",
          mega_menu: %{
            "admin_only" => [
              %{
                id: "admin_prod",
                label: "Admin Product",
                navigate: "/admin",
                permissions: "admin"
              }
            ]
          }
        },
        %{id: "public", label: "Public", navigate: "/public"}
      ]

      result = NavBuddy.filter_by_permissions(items, "read")
      assert length(result) == 1
      assert hd(result).id == "public"
    end
  end

  describe "mega menu validation" do
    test "validates simple mega menu format" do
      simple_mega_menu = %{
        "Frontend" => [
          %{id: "react", label: "React", navigate: "/tools/react"}
        ],
        "Backend" => [
          %{id: "elixir", label: "Elixir", navigate: "/tools/elixir"}
        ]
      }

      item = %{
        id: "tools",
        label: "Tools",
        mega_menu: simple_mega_menu
      }

      assert {:ok, _} = NavBuddy.validate_nav_item(item)
    end

    test "validates structured mega menu format with required fields only" do
      structured_mega_menu = %{
        title: "Our Tools",
        sections: [
          %{
            title: "Frontend",
            items: [
              %{id: "react", label: "React", navigate: "/tools/react"}
            ]
          }
        ]
      }

      item = %{
        id: "tools",
        label: "Tools",
        mega_menu: structured_mega_menu
      }

      assert {:ok, _} = NavBuddy.validate_nav_item(item)
    end

    test "validates structured mega menu format with optional description fields" do
      structured_mega_menu = %{
        title: "Our Tools",
        description: "Development tools and frameworks",
        sections: [
          %{
            title: "Frontend",
            description: "Client-side tools",
            items: [
              %{id: "react", label: "React", navigate: "/tools/react"}
            ]
          }
        ]
      }

      item = %{
        id: "tools",
        label: "Tools",
        mega_menu: structured_mega_menu
      }

      assert {:ok, _} = NavBuddy.validate_nav_item(item)
    end
  end

  describe "safe navigation item handling" do
    test "handles minimal navigation items without KeyErrors" do
      # Test that minimal items (only id and label) don't cause KeyErrors
      minimal_item = %{
        id: "minimal",
        label: "Minimal Item"
      }

      assert {:ok, _} = NavBuddy.validate_nav_item(minimal_item)
    end

    test "handles items with some but not all optional fields" do
      # Test that items with only some optional fields don't cause KeyErrors
      partial_item = %{
        id: "partial",
        label: "Partial Item",
        navigate: "/partial",
        active: true
        # Missing: icon, disabled, dropdown, mega_menu, permissions
      }

      assert {:ok, _} = NavBuddy.validate_nav_item(partial_item)
    end

    test "filters minimal items by permissions without errors" do
      # Test that permission filtering works with minimal items
      items = [
        %{id: "minimal1", label: "Minimal 1"},
        %{id: "minimal2", label: "Minimal 2", permissions: "admin"},
        %{id: "partial", label: "Partial", navigate: "/partial", active: true}
      ]

      result = NavBuddy.filter_by_permissions(items, ["user"])
      # Should return minimal1 and partial (no permissions required)
      assert length(result) == 2
      assert Enum.any?(result, &(&1.id == "minimal1"))
      assert Enum.any?(result, &(&1.id == "partial"))
    end
  end
end
