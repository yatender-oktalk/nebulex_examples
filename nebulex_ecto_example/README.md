# Nebulex and Ecto Integration Example

This example illustrates how to integrate [Nebulex](https://github.com/cabol/nebulex)
and [Ecto](https://github.com/elixir-ecto/ecto) extremely easy, using
[nebulex_ecto](https://github.com/cabol/nebulex_ecto) library.

This is the behaviour that we want and is precisely what `nebulex_ecto` does:

* For retrieve-like functions, the idea is to access the cache first, if the
  requested data is found there, then it is returned right away, otherwise,
  try to retrieve the data from the repo (database), and if the data is found,
  then put it into cache so the next time it can be retrieved directly from
  there.

* For write functions (insert, update, delete, ...), the idea is to run an
  eviction logic, which can be delete the data from cache or just replace it.

> Check out [Nebulex.Ecto.Repo](https://github.com/cabol/nebulex_ecto/blob/master/lib/nebulex_ecto/repo.ex)
  documentation.

The module [NebulexEctoExample.CacheableRepo](lib/nebulex_ecto/cacheable_repo.ex)
uses `Nebulex.Ecto.Repo` to encapsulate the required logic described above.
As you can see in the [config](config/config.exs), this module encapsulates the
[cache](lib/nebulex_ecto/cache.ex) and the [repo](lib/nebulex_ecto/repo.ex).

Let's see how it works!

## Getting started

First of all, let's setup the database:

```
$ mix ecto.create
$ mix ecto.migrate
```

Now we have the database setup and ready to be used.

Open an interactive Elixir console:

```
iex -S mix
```

Let's play a bit:

```elixir
iex(1)> alias NebulexEctoExample.Person
NebulexEctoExample.Person

iex(2)> alias NebulexEctoExample.CacheableRepo
NebulexEctoExample.CacheableRepo

iex(3)> person = %Person{first_name: "Carlos", last_name: "Bolanos", age: 33}
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:built, "people">,
  age: 33,
  first_name: "Carlos",
  id: nil,
  last_name: "Bolanos"
}

iex(4)> CacheableRepo.get(Person, 1)

15:45:25.700 [debug] QUERY OK source="people" db=2.3ms
SELECT p0."id", p0."first_name", p0."last_name", p0."age" FROM "people" AS p0 WHERE (p0."id" = $1) [1]
nil

iex(5)> NebulexEctoExample.Cache.get({Person, 1})
nil

iex(6)> {:ok, person} = CacheableRepo.insert(person)

15:45:53.386 [debug] QUERY OK db=2.9ms queue=0.1ms
INSERT INTO "people" ("age","first_name","last_name") VALUES ($1,$2,$3) RETURNING "id" [33, "Carlos", "Bolanos"]
{:ok,
 %NebulexEctoExample.Person{
   __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
   age: 33,
   first_name: "Carlos",
   id: 1,
   last_name: "Bolanos"
 }}

iex(7)> CacheableRepo.get(Person, 1)

15:46:14.746 [debug] QUERY OK source="people" db=2.8ms decode=2.8ms
SELECT p0."id", p0."first_name", p0."last_name", p0."age" FROM "people" AS p0 WHERE (p0."id" = $1) [1]
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
  age: 33,
  first_name: "Carlos",
  id: 1,
  last_name: "Bolanos"
}

iex(8)> NebulexEctoExample.Cache.get({Person, 1})
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
  age: 33,
  first_name: "Carlos",
  id: 1,
  last_name: "Bolanos"
}
```

So far seems to be working as expected, let's force some evictions:

```elixir
iex(9)> changeset = Ecto.Changeset.change person, last_name: "Andres"
#Ecto.Changeset<
  action: nil,
  changes: %{last_name: "Andres"},
  errors: [],
  data: #NebulexEctoExample.Person<>,
  valid?: true
>

iex(10)> person = CacheableRepo.update!(changeset)

15:47:30.690 [debug] QUERY OK db=8.3ms
UPDATE "people" SET "last_name" = $1 WHERE "id" = $2 ["Andres", 1]
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
  age: 33,
  first_name: "Carlos",
  id: 1,
  last_name: "Andres"
}

iex(11)> NebulexEctoExample.Cache.get({Person, 1})
nil

iex(12)> person = CacheableRepo.update!(changeset, nbx_evict: :replace)

15:47:54.464 [debug] QUERY OK db=5.5ms decode=0.2ms
UPDATE "people" SET "last_name" = $1 WHERE "id" = $2 ["Andres", 1]
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
  age: 33,
  first_name: "Carlos",
  id: 1,
  last_name: "Andres"
}

iex(13)> NebulexEctoExample.Cache.get({Person, 1})
%NebulexEctoExample.Person{
  __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
  age: 33,
  first_name: "Carlos",
  id: 1,
  last_name: "Andres"
}
```

It works! You can continue testing more functions!
