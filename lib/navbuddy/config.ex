defmodule NavBuddy.Config do
  @moduledoc """
  Configuration struct for NavBuddy navigation components.

  This module defines the configuration options available for customizing
  the behavior and appearance of NavBuddy navigation components.

  ## Configuration Options

  - `orientation`: Navigation layout direction (`:horizontal` | `:vertical`)
  - `theme`: Color theme (`:light` | `:dark` | `:auto`)
  - `dropdown_trigger`: How dropdowns are activated (`:hover` | `:click`)
  - `mobile_behavior`: Mobile navigation behavior (`:drawer` | `:collapse` | `:overlay`)
  - `animations`: Enable/disable animations (`boolean`)
  - `accessibility`: Enable accessibility features (`boolean`)
  - `mobile_breakpoint`: Pixel width for mobile breakpoint (`integer`)
  - `max_dropdown_depth`: Maximum nesting levels for dropdowns (`integer`)
  - `auto_close_delay`: Delay before auto-closing dropdowns in ms (`integer`)
  - `touch_gestures`: Enable touch gesture support (`boolean`)
  - `analytics`: Enable analytics event tracking (`boolean`)

  ## Examples

      # Default configuration
      %NavBuddy.Config{}

      # Custom configuration
      %NavBuddy.Config{
        orientation: :vertical,
        theme: :dark,
        dropdown_trigger: :click,
        mobile_behavior: :overlay,
        animations: false
      }
  """

  @enforce_keys []
  defstruct orientation: :horizontal,
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

  @type orientation :: :horizontal | :vertical
  @type theme :: :light | :dark | :auto
  @type dropdown_trigger :: :hover | :click
  @type mobile_behavior :: :drawer | :collapse | :overlay

  @type t :: %__MODULE__{
          orientation: orientation(),
          theme: theme(),
          dropdown_trigger: dropdown_trigger(),
          mobile_behavior: mobile_behavior(),
          animations: boolean(),
          accessibility: boolean(),
          mobile_breakpoint: non_neg_integer(),
          max_dropdown_depth: pos_integer(),
          auto_close_delay: non_neg_integer(),
          touch_gestures: boolean(),
          analytics: boolean()
        }

  @doc """
  Validates a configuration struct.

  Returns `{:ok, config}` if valid, `{:error, reason}` if invalid.

  ## Examples

      iex> config = %NavBuddy.Config{orientation: :horizontal}
      iex> NavBuddy.Config.validate(config)
      {:ok, %NavBuddy.Config{orientation: :horizontal}}

      iex> config = %NavBuddy.Config{orientation: :invalid}
      iex> NavBuddy.Config.validate(config)
      {:error, "Invalid orientation: :invalid"}
  """
  def validate(%__MODULE__{} = config) do
    with :ok <- validate_orientation(config.orientation),
         :ok <- validate_theme(config.theme),
         :ok <- validate_dropdown_trigger(config.dropdown_trigger),
         :ok <- validate_mobile_behavior(config.mobile_behavior),
         :ok <- validate_mobile_breakpoint(config.mobile_breakpoint),
         :ok <- validate_max_dropdown_depth(config.max_dropdown_depth),
         :ok <- validate_auto_close_delay(config.auto_close_delay) do
      {:ok, config}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(config) do
    {:error, "Config must be a NavBuddy.Config struct, got: #{inspect(config)}"}
  end

  defp validate_orientation(:horizontal), do: :ok
  defp validate_orientation(:vertical), do: :ok
  defp validate_orientation(other), do: {:error, "Invalid orientation: #{inspect(other)}"}

  defp validate_theme(:light), do: :ok
  defp validate_theme(:dark), do: :ok
  defp validate_theme(:auto), do: :ok
  defp validate_theme(other), do: {:error, "Invalid theme: #{inspect(other)}"}

  defp validate_dropdown_trigger(:hover), do: :ok
  defp validate_dropdown_trigger(:click), do: :ok

  defp validate_dropdown_trigger(other),
    do: {:error, "Invalid dropdown_trigger: #{inspect(other)}"}

  defp validate_mobile_behavior(:drawer), do: :ok
  defp validate_mobile_behavior(:collapse), do: :ok
  defp validate_mobile_behavior(:overlay), do: :ok
  defp validate_mobile_behavior(other), do: {:error, "Invalid mobile_behavior: #{inspect(other)}"}

  defp validate_mobile_breakpoint(breakpoint) when is_integer(breakpoint) and breakpoint > 0,
    do: :ok

  defp validate_mobile_breakpoint(other),
    do: {:error, "Mobile breakpoint must be a positive integer, got: #{inspect(other)}"}

  defp validate_max_dropdown_depth(depth) when is_integer(depth) and depth > 0 and depth <= 10,
    do: :ok

  defp validate_max_dropdown_depth(other),
    do: {:error, "Max dropdown depth must be between 1 and 10, got: #{inspect(other)}"}

  defp validate_auto_close_delay(delay) when is_integer(delay) and delay >= 0, do: :ok

  defp validate_auto_close_delay(other),
    do: {:error, "Auto close delay must be a non-negative integer, got: #{inspect(other)}"}

  @doc """
  Merges two configurations, with the second taking precedence.

  ## Examples

      iex> base = %NavBuddy.Config{orientation: :horizontal, theme: :light}
      iex> override = %NavBuddy.Config{theme: :dark}
      iex> NavBuddy.Config.merge(base, override)
      %NavBuddy.Config{orientation: :horizontal, theme: :dark}
  """
  def merge(%__MODULE__{} = base, %__MODULE__{} = override) do
    Map.merge(base, Map.from_struct(override))
    |> then(&struct(__MODULE__, &1))
  end

  @doc """
  Converts configuration to CSS custom properties.

  Returns a map of CSS custom property names to values.

  ## Examples

      iex> config = %NavBuddy.Config{mobile_breakpoint: 768, auto_close_delay: 300}
      iex> NavBuddy.Config.to_css_properties(config)
      %{
        "--navbuddy-mobile-breakpoint" => "768px",
        "--navbuddy-auto-close-delay" => "300ms"
      }
  """
  def to_css_properties(%__MODULE__{} = config) do
    %{
      "--navbuddy-mobile-breakpoint" => "#{config.mobile_breakpoint}px",
      "--navbuddy-auto-close-delay" => "#{config.auto_close_delay}ms",
      "--navbuddy-max-dropdown-depth" => "#{config.max_dropdown_depth}"
    }
  end

  @doc """
  Converts configuration to HTML data attributes.

  Returns a map of data attribute names to values.

  ## Examples

      iex> config = %NavBuddy.Config{orientation: :horizontal, theme: :dark}
      iex> NavBuddy.Config.to_data_attributes(config)
      %{
        "data-orientation" => "horizontal",
        "data-theme" => "dark",
        "data-dropdown-trigger" => "hover",
        "data-mobile-behavior" => "drawer"
      }
  """
  def to_data_attributes(%__MODULE__{} = config) do
    %{
      "data-orientation" => to_string(config.orientation),
      "data-theme" => to_string(config.theme),
      "data-dropdown-trigger" => to_string(config.dropdown_trigger),
      "data-mobile-behavior" => to_string(config.mobile_behavior),
      "data-animations" => to_string(config.animations),
      "data-accessibility" => to_string(config.accessibility),
      "data-touch-gestures" => to_string(config.touch_gestures),
      "data-analytics" => to_string(config.analytics)
    }
  end
end
