defmodule Crit.Users.PasswordToken2 do
  use Ecto.Schema
  alias Crit.EmailToken
  import Ecto.Changeset
  alias Crit.Repo
#  import Ecto.Query
#  alias Crit.Institutions.Institution

  @schema_prefix "clients"
  
  schema "all_password_tokens" do
    field :text, :string
    field :user_id, :id
    field :institution_short_name, :string

    timestamps(inserted_at: false)
  end

  def new(user_id, institution) do
    %__MODULE__{user_id: user_id,
                institution_short_name: institution,
                text: EmailToken.generate()
    }
  end

  @expiration_in_seconds (7 * 24 * 60 * 60)

  def expiration_threshold(now \\ NaiveDateTime.utc_now) do
    NaiveDateTime.add(now, -1 * @expiration_in_seconds)
  end

  def force_update(token, datetime) do
    for_postgres = NaiveDateTime.truncate(datetime, :second)

    change(token, updated_at: for_postgres) |> Repo.update
    :ok
  end


  
  defmodule Query do
    import Ecto.Query
    alias Crit.Users.PasswordToken2

    def by(opts),
      do: from PasswordToken2, where: ^opts
  
    def expired_tokens do
      from r in PasswordToken2,
        where: r.updated_at < ^PasswordToken2.expiration_threshold()
    end
  end
  
end
