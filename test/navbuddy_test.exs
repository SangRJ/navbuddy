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
end
