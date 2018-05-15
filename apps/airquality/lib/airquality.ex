defmodule Airquality do
  @moduledoc """
  Airquality keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @behaviour Airquality.Behaviour

  alias __MODULE__.{Data, Sources.OpenAQ, TaskSupervisor}

  @source Application.get_env(:airquality, :source)

  defmodule Behaviour do
    @callback search_locations(search_term :: String.t()) :: [%Airquality.Data.Location{}]
    @callback search_locations(lat :: number, lon :: number) :: [%Airquality.Data.Location{}]
    @callback get_measurements(location_id :: integer | String.t()) :: [
                %Airquality.Data.Measurement{}
              ]
  end

  def search_locations(search_term) do
    case Data.find_locations(search_term) do
      [] ->
        @source.get_locations(search_term)

      locations ->
        {:ok, _pid} =
          Task.Supervisor.start_child(TaskSupervisor, fn ->
            @source.get_locations(search_term)
          end)

        locations
    end
  end

  def search_locations(lat, lon) do
    case Data.find_locations(lat, lon) do
      [] ->
        @source.get_locations(lat, lon)

      locations ->
        {:ok, _pid} =
          Task.Supervisor.start_child(TaskSupervisor, fn ->
            @source.get_locations(lat, lon)
          end)

        locations
    end
  end

  def get_measurements(location_id) do
    OpenAQ.get_latest_measurements(location_id)
  end
end
