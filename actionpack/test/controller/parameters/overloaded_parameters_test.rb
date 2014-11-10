require 'abstract_unit'
require 'action_controller/metal/strong_parameters'

class OverloadedParametersTest < ActiveSupport::TestCase
  def assert_filtered_out(params, key)
    assert !params.has_key?(key), "key #{key.inspect} has not been filtered out"
  end

  test "permitted overloaded parameters" do
    permitted_params = {
      agency: [
        :person,
        {person: [ :name, :weapon_of_choice ]},
        {person: []}
      ]
    }

    scalar_params = ActionController::Parameters.new({
      agency: {
        person: "James Bond"
      },
      badness: "Goldfinger"
    })

    hash_params = ActionController::Parameters.new({
      agency: {
        person: {
          name: "Jason Bourne",
          weapon_of_choice: "pen",
          badness: "Goldfinger"
        }
      }
    })

    array_params = ActionController::Parameters.new({
      agency: {
        person: ["James Bond", "007"],
        badness: "Goldfinger"
      }
    })

    scalar_permitted = scalar_params.permit permitted_params
    hash_permitted = hash_params.permit permitted_params
    array_permitted = array_params.permit permitted_params

    assert scalar_permitted.permitted?
    assert hash_permitted.permitted?
    assert array_permitted.permitted?
    assert_equal "James Bond", scalar_permitted[:agency][:person]
    assert_equal "Jason Bourne", hash_permitted[:agency][:person][:name]
    assert_equal "pen", hash_permitted[:agency][:person][:weapon_of_choice]
    assert_equal ["James Bond", "007"], array_permitted[:agency][:person]

    assert_filtered_out scalar_permitted, :badness
    assert_filtered_out hash_permitted[:agency][:person], :badness
    assert_filtered_out array_permitted[:agency], :badness
  end

  test "permitted overloaded parameters with hash then scalar" do
    permitted_params = {
      agency: [
        {person: [ :name, :weapon_of_choice ]},
        :person,
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        person: {
          name: "Jason Bourne",
          weapon_of_choice: "pen",
          badness: "Goldfinger"
        }
      }
    })

    scalar_params = ActionController::Parameters.new({
      agency: {
        person: "James Bond"
      },
      badness: "Goldfinger"
    })

    hash_permitted = hash_params.permit permitted_params
    scalar_permitted = scalar_params.permit permitted_params

    assert hash_permitted.permitted?
    assert scalar_permitted.permitted?

    assert_equal "Jason Bourne", hash_permitted[:agency][:person][:name]
    assert_equal "pen", hash_permitted[:agency][:person][:weapon_of_choice]
    assert_equal "James Bond", scalar_permitted[:agency][:person]

    assert_filtered_out hash_permitted[:agency][:person], :badness
    assert_filtered_out scalar_permitted, :badness
  end

  test "permitted overloaded parameters with array then scalar" do
    permitted_params = {
      agency: [
        {person: []},
        :person,
      ]
    }

    array_params = ActionController::Parameters.new({
      agency: {
        person: ["James Bond", "007"],
        badness: "Goldfinger"
      }
    })

    scalar_params = ActionController::Parameters.new({
      agency: {
        person: "James Bond"
      },
      badness: "Goldfinger"
    })

    array_permitted = array_params.permit permitted_params
    scalar_permitted = scalar_params.permit permitted_params

    assert array_permitted.permitted?
    assert scalar_permitted.permitted?

    assert_equal ["James Bond", "007"], array_permitted[:agency][:person]
    assert_equal "James Bond", scalar_permitted[:agency][:person]

    assert_filtered_out array_permitted[:agency], :badness
    assert_filtered_out scalar_permitted, :badness
  end

  test "permitted overloaded parameters with array then hash" do
    permitted_params = {
      agency: [
        {person: []},
        {person: [ :name, :weapon_of_choice ]},
      ]
    }

    array_params = ActionController::Parameters.new({
      agency: {
        person: ["James Bond", "007"],
        badness: "Goldfinger"
      }
    })

    hash_params = ActionController::Parameters.new({
      agency: {
        person: {
          name: "Jason Bourne",
          weapon_of_choice: "pen",
          badness: "Goldfinger"
        }
      }
    })

    array_permitted = array_params.permit permitted_params
    hash_permitted = hash_params.permit permitted_params

    assert array_permitted.permitted?
    assert hash_permitted.permitted?

    assert_equal ["James Bond", "007"], array_permitted[:agency][:person]
    assert_equal "Jason Bourne", hash_permitted[:agency][:person][:name]
    assert_equal "pen", hash_permitted[:agency][:person][:weapon_of_choice]

    assert_filtered_out array_permitted[:agency], :badness
    assert_filtered_out hash_permitted[:agency][:person], :badness
  end

  test "permitted overloaded string and symbol parameters as keys" do
    permitted_params = {
      agency: [
        {persons: []},
        {persons: [ :name, :weapon_of_choice ]},
      ]
    }

    array_params = ActionController::Parameters.new({
      agency: {
        'persons' => ["James Bond", "Alec Trevelyan"],
        :badness => "Goldfinger"
      }
    })

    permitted = array_params.permit permitted_params

    assert_equal 'James Bond', permitted[:agency]['persons'][0]
    assert_equal 'James Bond', permitted[:agency][:persons][0]
    assert_equal 'Alec Trevelyan', permitted[:agency]['persons'][1]
    assert_equal 'Alec Trevelyan', permitted[:agency][:persons][1]

    permitted_params = {
      agency: [
        {persons: []},
        {'persons' => [ :name, :weapon_of_choice ]},
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: [
          {
            name: "Jason Bourne",
            weapon_of_choice: "pen",
          },
          {
            name: "Aaron Cross",
            weapon_of_choice: "spoon",
          },
        ]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal 'Jason Bourne', permitted[:agency]['persons'][0][:name]
    assert_equal 'Jason Bourne', permitted[:agency][:persons][0][:name]
    assert_equal 'Aaron Cross', permitted[:agency]['persons'][1][:name]
    assert_equal 'Aaron Cross', permitted[:agency][:persons][1][:name]
  end

  test "permitted overloaded parameters with array then array of hashes" do
    permitted_params = {
      agency: [
        {persons: []},
        {:persons => [ :name, :weapon_of_choice ]},
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: [
          {
            name: "Jason Bourne",
            weapon_of_choice: "pen",
          },
          {
            name: "Aaron Cross",
            weapon_of_choice: "spoon",
          },
        ]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal 'Jason Bourne', permitted[:agency][:persons][0][:name]
    assert_equal 'Aaron Cross', permitted[:agency][:persons][1][:name]

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: ["Jason Bourne", "Aaron Cross"]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal 'Jason Bourne', permitted[:agency][:persons][0]
    assert_equal 'Aaron Cross', permitted[:agency][:persons][1]
  end

  test "permitted overloaded parameters with array of hashes then array" do
    permitted_params = {
      agency: [
        {:persons => [ :name ]},
        {persons: []},
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: [
          {
            name: "Jason Bourne",
            weapon_of_choice: "pen",
          },
          {
            name: "Aaron Cross",
            weapon_of_choice: "spoon",
          },
        ]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal 'Jason Bourne', permitted[:agency][:persons][0][:name]
    assert_equal 'Aaron Cross', permitted[:agency][:persons][1][:name]

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: ["Jason Bourne", "Aaron Cross"]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal 'Jason Bourne', permitted[:agency][:persons][0]
    assert_equal 'Aaron Cross', permitted[:agency][:persons][1]
  end

  test "permitted overloaded parameters with array of hashes then array of scalars" do
    permitted_params = {
      agency: [
        {:persons => [ :name ]},
        {persons: []},
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: [:name, 007]
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal :name, permitted[:agency][:persons][0]
    assert_equal 007, permitted[:agency][:persons][1]
  end

  test "permitted overloaded parameters with Hash, array, and scalar" do
    permitted_params = {
      agency: [
        {:persons => [ :name ]},
        {persons: []},
        :persons,
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons: "Billy, Bob, Jean"
      }
    })

    permitted = hash_params.permit permitted_params

    assert_equal "Billy, Bob, Jean", permitted[:agency][:persons]
  end

  test "permitted overloaded parameters with field_for-style hashes" do
    permitted_params = {
      agency: [
        {:persons_attributes => [ :name ]},
        {persons_attributes: []},
        :persons_attributes
      ]
    }

    hash_params = ActionController::Parameters.new({
      agency: {
        persons_attributes: {
          :'0' => { name: 'Billy', age_of_death: '52' },
          :'1' => { name: 'Unattributed Assistant' },
          :'2' => { name: %w(injected names)}
        }
      }
    })

    permitted = hash_params.permit permitted_params

    assert_not_nil permitted[:agency][:persons_attributes]['0']
    assert_not_nil permitted[:agency][:persons_attributes]['1']
    assert_empty permitted[:agency][:persons_attributes]['2']
    assert_equal 'Billy', permitted[:agency][:persons_attributes]['0'][:name]
    assert_equal 'Unattributed Assistant', permitted[:agency][:persons_attributes]['1'][:name]

    assert_filtered_out permitted[:agency][:persons_attributes]['0'], :age_of_death
  end

  test "fields_for-style nested params with negative numbers" do
    permitted_params = {
      book: [
        {:authors_attributes => [ :name ]},
        {authors_attributes: []},
        :authors_attributes
      ]
    }

    params = ActionController::Parameters.new({
      book: {
        authors_attributes: {
          :'-1' => { name: 'William Shakespeare', age_of_death: '52' },
          :'-2' => { name: 'Unattributed Assistant' }
        }
      }
    })
    permitted = params.permit permitted_params

    assert_not_nil permitted[:book][:authors_attributes]['-1']
    assert_not_nil permitted[:book][:authors_attributes]['-2']
    assert_equal 'William Shakespeare', permitted[:book][:authors_attributes]['-1'][:name]
    assert_equal 'Unattributed Assistant', permitted[:book][:authors_attributes]['-2'][:name]

    assert_filtered_out permitted[:book][:authors_attributes]['-1'], :age_of_death
  end

  test "nested number as key" do
    permitted_params = [
      {:properties => ["0"]},
      {:properties => []}
    ]

    params = ActionController::Parameters.new({
      product: {
        properties: {
          '0' => "prop0",
          '1' => "prop1"
        }
      }
    })

    params = params.require(:product).permit permitted_params
    assert_not_nil        params[:properties]["0"]
    assert_nil            params[:properties]["1"]
    assert_equal "prop0", params[:properties]["0"]

    params = ActionController::Parameters.new({
      product: {
        properties: [0]
      }
    })

    params = params.require(:product).permit permitted_params
    assert_equal 0, params[:properties][0]
  end
end
