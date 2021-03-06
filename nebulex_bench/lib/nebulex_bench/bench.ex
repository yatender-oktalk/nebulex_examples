defmodule NebulexBench.Bench do
  @moduledoc false

  @cache Keyword.get(
           Application.get_env(:nebulex_bench, NebulexBench.Bench, []),
           :bench_cache,
           NebulexBench.LocalCache
         )

  def new(_state) do
    {:ok, %{}}
  end

  def run(:set, key_gen, value_gen, state) do
    value = value_gen.()
    ^value = @cache.set(key_gen.(), value)
    {:ok, state}
  end

  def run(:get, key_gen, _value_gen, state) do
    @cache.get(key_gen.())
    {:ok, state}
  end

  def run(:del, key_gen, _value_gen, state) do
    key = key_gen.()
    ^key = @cache.delete(key)
    {:ok, state}
  end

  ## You can add more functions to bench here
end
