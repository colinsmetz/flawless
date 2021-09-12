defmodule Validator.Spec do
  @moduledoc """
  A structure for defining the spec of a schema element.

  The `for` attribute allows to define type-specific specs.
  """
  defstruct checks: [], late_checks: [], type: :any, cast_from: [], nil: :default, for: nil

  @type t() :: %__MODULE__{
          checks: list(Validator.Rule.t()),
          late_checks: list(Validator.Rule.t()),
          type: atom(),
          cast_from: list(atom()) | atom(),
          nil: :default | true | false,
          for:
            Validator.Spec.Value.t()
            | Validator.Spec.Struct.t()
            | Validator.Spec.List.t()
            | Validator.Spec.Tuple.t()
            | Validator.Spec.Literal.t()
        }

  defmodule Value do
    @moduledoc """
    Represents a simple value or a map.

    The `schema` field is used when the value is a map, and is `nil` otherwise.
    """
    defstruct schema: nil

    @type t() :: %__MODULE__{
            schema: map() | nil
          }
  end

  defmodule Struct do
    @moduledoc """
    Represents a struct.
    """
    defstruct schema: nil,
              module: nil

    @type t() :: %__MODULE__{
            schema: map() | nil,
            module: atom()
          }
  end

  defmodule List do
    @moduledoc """
    Represents a list of elements.

    Each element must conform to the `item_type` definition.
    """
    defstruct item_type: nil

    @type t() :: %__MODULE__{
            item_type: Validator.spec_type()
          }
  end

  defmodule Tuple do
    @moduledoc """
    Represents a tuple.

    Matching values are expected to be a tuple with the same
    size as elem_types, and matching the rule for each element.
    """
    defstruct elem_types: nil

    @type t() :: %__MODULE__{
            elem_types: {Validator.spec_type()}
          }
  end

  defmodule Literal do
    @moduledoc """
    Represents a literal constant.

    Matching values are expected to be strictly equal to the value.
    """

    defstruct value: nil

    @type t() :: %__MODULE__{
            value: any()
          }
  end
end
