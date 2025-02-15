defmodule Snap do
  @moduledoc """
  Snap is split into 3 main components:

  * `Snap.Cluster` - clusters are wrappers around the Elasticsearch HTTP API.
    We can use this to perform low-level HTTP requests.

  * `Snap.Bulk` - a convenience wrapper around bulk operations, using `Stream`
    to stream actions (such as `Snap.Bulk.Action.Create`) to be performed
    against the `Snap.Cluster`.

  * `Snap.Indexes` - a convenience wrapper around the Elasticsearch indexes
    APIs, allowing the creation, deleting and aliasing of indexes, along with
    hotswap functionality to bulk load documents into an aliased index,
    switching to it atomically.

  Additionally, there are other supporting modules:

  * `Snap.HTTPClient` - defines how to send HTTP requests.
    Comes with a built in adapter for `Finch` (`Snap.HTTPClient.Adapters.Finch`)

  * `Snap.Auth` - defines how an HTTP request is modified to include
    authentication headers. `Snap.Auth.Plain` implements HTTP Basic Auth.

  ## Set up

  `Snap.Cluster` is a wrapped around an Elasticsearch cluster. We can define
  it like so:

  ```
  defmodule MyApp.Cluster do
    use Snap.Cluster, otp_app: :my_app
  end
  ```

  The configuration for the cluster can be defined in your config:

  ```
  config :my_app, MyApp.Cluster,
    url: "http://localhost:9200",
    username: "username",
    password: "password"
  ```

  Or you can load it dynamically by implementing `c:Snap.Cluster.init/1`.

  Each cluster defines `start_link/1` which must be invoked before using the
  cluster and optionally accepts an explicit config. It creates the
  supervision tree, including the connection pool.

  Include it in your application:

  ```
  def start(_type, _args) do
    children = [
      {MyApp.Cluster, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  ## Config

  The following configuration options are supported:

  * `url` - the URL of the Elasticsearch HTTP endpoint (required)
  * `username` - the username used to access the cluster
  * `password` - the password used to access the cluster
  * `auth` - the auth module used to configure the HTTP authentication headers
    (defaults to `Snap.Auth.Plain`)
  * `http_client_adapter` - the adapter that will be used to send HTTP requests.
    Check `Snap.HTTPClient` for more information.
    (defaults to `Snap.HTTPClient.Adapters.Finch`)
  * `telemetry_prefix` - the prefix of the telemetry events (defaults to
    `[:my_app, :snap]`)

  ## Telemetry

  Snap supports sending `Telemetry` events on each HTTP request. It sends one
  event per query, of the name `[:my_app, :snap, :request]`.

  The telemetry event has the following measurements:

  * `response_time` - how long the request took to return
  * `decode_time` - how long the response took to decode into a map or
    exception
  * `total_time` - how long everything took in total

  In addition, the metadata contains a map of:

  * `method` - the HTTP method used
  * `path` - the path requested
  * `port` - the port requested
  * `host` - the host requested
  * `headers` - a list of the headers sent
  * `body` - the body sent
  * `result` - the result returned to the user
  """

  alias Snap.Request

  @doc false
  def get(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :get, path, nil, params, headers, opts)
  end

  @doc false
  def post(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :post, path, body, params, headers, opts)
  end

  @doc false
  def put(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :put, path, body, params, headers, opts)
  end

  @doc false
  def delete(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :delete, path, nil, params, headers, opts)
  end
end
