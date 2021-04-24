defmodule Waffle.Transformations.CustomConvert do
  @moduledoc false

  def apply(file, executor, extension \\ nil)

  def apply(file, executor, extension) when is_function(executor) do
    new_path =
      if extension,
        do: Waffle.File.generate_temporary_path(extension),
        else: Waffle.File.generate_temporary_path(file)

    result = executor.(file.path, new_path)

    case result do
      {:ok, _file} ->
        {:ok, %Waffle.File{file | path: new_path, is_tempfile?: true}}

      {:error, error_message} ->
        {:error, error_message}
    end
  end

  def apply(_file, _executor, _extension) do
    {:error, :invalid_custom_ops}
  end
end
