class ApplicationController < ActionController::Base
  class QueryError < StandardError; end

  private
    def query(definition, variables = {})
      response = GitHub::Client.query(definition, variables: variables, context: client_context)

      if response.errors.any?
        raise QueryError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end

    # Public: Useful helper method for tracking GraphQL context data to pass
    # along to the network adapter.
    def client_context
      # Use static access token from environment. However, here we have access
      # to the current request so we could configure the token to be retrieved
      # from a session cookie.
      { access_token: GitHub::Application.secrets.github_access_token }
    end
end
